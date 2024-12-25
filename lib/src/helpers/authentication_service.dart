import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthenticationService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  /// Sign in anonymously
  Future<UserModel?> signInAnonymously() async {
    try {
      UserCredential result = await auth.signInAnonymously();
      User? user = result.user;

      if (user != null) {
        // Create a new document for the user in Firestore if it doesn't exist
        DocumentSnapshot doc = await db.collection('Users').doc(user.uid).get();
        if (!doc.exists) {
          UserModel userModel = UserModel(
            userId: user.uid,
          );
          await db.collection('Users').doc(user.uid).set(userModel.toMap());
          return userModel;
        } else {
          return UserModel.fromDocument(doc);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }

    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await auth.signOut();
  }

  // Link anonymous account to email and password
  Future<UserModel?> linkAnonymousAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      User? user = auth.currentUser;

      if (user != null && user.isAnonymous) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        UserCredential result = await user.linkWithCredential(credential);
        User? linkedUser = result.user;

        if (linkedUser != null) {
          // Update user document in Firestore
          UserModel userModel = UserModel(
            userId: linkedUser.uid,
            email: email,
          );
          await db
              .collection('Users')
              .doc(linkedUser.uid)
              .update(userModel.toMap());
          return userModel;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }

    return null;
  }
}
