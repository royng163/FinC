import 'package:finc/src/helpers/hive_service.dart';
import 'package:finc/src/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final _hiveService = HiveService();

  /// Returns the currently signed in user. Throws an exception if none is signed in.
  User getCurrentUser() {
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      return user;
    } catch (e) {
      throw Exception('Error retrieving current user: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        // Get or create the user document in Firestore
        DocumentSnapshot doc = await db.collection('Users').doc(user.uid).get();

        UserModel userModel;
        if (!doc.exists) {
          userModel = UserModel(
            userId: user.uid,
            email: email,
          );
          await db.collection('Users').doc(user.uid).set(userModel.toFirestore());
        } else {
          userModel = UserModel.fromFirestore(doc);
        }

        // Sync Firestore data to local Hive storage after successful login
        await _hiveService.syncData();

        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Authentication failed';

      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      }

      throw Exception(message);
    }

    return null;
  }

  /// Sign in anonymously
  Future<UserModel?> signInAnonymously() async {
    try {
      UserCredential credential = await auth.signInAnonymously();
      User? user = credential.user;

      if (user != null) {
        // Create a new document for the user in Firestore if it doesn't exist
        DocumentSnapshot doc = await db.collection('Users').doc(user.uid).get();
        if (!doc.exists) {
          UserModel userModel = UserModel(
            userId: user.uid,
          );
          await db.collection('Users').doc(user.uid).set(userModel.toFirestore());
          return userModel;
        } else {
          return UserModel.fromFirestore(doc);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }

    return null;
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Create the user in Firebase Auth
      UserCredential credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        // Create the user document in Firestore
        UserModel userModel = UserModel(
          userId: user.uid,
          email: email,
        );

        await db.collection('Users').doc(user.uid).set(userModel.toFirestore());
        return userModel;
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Registration failed';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use by another account.';
      } else if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      }

      throw Exception(message);
    }

    return null;
  }

  /// Re-authenticate the current user with their password
  /// This is required before performing security-sensitive operations
  Future<bool> reauthenticateWithPassword(String password) async {
    try {
      final user = auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No authenticated user with email found');
      }

      // Create credential
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Re-authenticate
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Re-authentication failed';

      if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'user-mismatch') {
        message = 'The credential does not match the current user';
      } else if (e.code == 'user-not-found') {
        message = 'User not found';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials';
      }

      throw Exception(message);
    }
  }

  Future<void> deleteCurrentUser() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        // Delete user's data from Firestore
        final batch = db.batch();

        // Delete user document
        batch.delete(db.collection('Users').doc(user.uid));

        final accountsQuery = await db.collection('Accounts').where('userId', isEqualTo: user.uid).get();
        for (var doc in accountsQuery.docs) {
          batch.delete(doc.reference);
        }

        final transactionsQuery = await db.collection('Transactions').where('userId', isEqualTo: user.uid).get();
        for (var doc in transactionsQuery.docs) {
          batch.delete(doc.reference);
        }

        final tagsQuery = await db.collection('Tags').where('userId', isEqualTo: user.uid).get();
        for (var doc in tagsQuery.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        // Delete the actual Firebase Auth user
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

// Replace the existing signOut method
  Future<void> signOut() async {
    final user = auth.currentUser;
    final isAnonymous = user?.isAnonymous ?? false;

    if (isAnonymous && user != null) {
      // Delete the anonymous user completely
      await deleteCurrentUser();
    }

    // Sign out regardless
    await auth.signOut();
  }

  /// Upgrade an anonymous account to a permanent email and password account
  Future<UserModel?> upgradeAnonymousToEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      User? user = auth.currentUser;

      if (user != null && user.isAnonymous) {
        // Create credential with user-provided email and password
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        // Link the anonymous user with the email credential
        UserCredential result = await user.linkWithCredential(credential);
        User? linkedUser = result.user;

        if (linkedUser != null) {
          // Update user document in Firestore
          UserModel userModel = UserModel(
            userId: linkedUser.uid,
            email: email,
          );

          await db.collection('Users').doc(linkedUser.uid).update(userModel.toFirestore());

          return userModel;
        }
      } else {
        throw Exception('No anonymous user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Failed to upgrade account';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use by another account';
      } else if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password accounts are not enabled';
      }

      throw Exception(message);
    } catch (e) {
      throw Exception('Failed to upgrade account: $e');
    }

    return null;
  }
}
