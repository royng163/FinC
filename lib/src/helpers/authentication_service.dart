import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthenticationService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  /// Send sign-in link to email
  Future<void> sendSignInLinkToEmail({required String email}) async {
    try {
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: 'https://yourapp.page.link/signin',
        handleCodeInApp: true,
        iOSBundleId: 'com.example.ios',
        androidPackageName: 'com.example.android',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );

      await auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
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

  // Link anonymous account to email only
  Future<UserModel?> linkAnonymousAccount({
    required String email,
  }) async {
    try {
      User? user = auth.currentUser;

      if (user != null && user.isAnonymous) {
        // Create a temporary password for linking
        String tempPassword = 'TempPassword123!';

        // Create email credential with temporary password
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: tempPassword,
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
          await db
              .collection('Users')
              .doc(linkedUser.uid)
              .update(userModel.toMap());

          // Update the user's email without requiring a password
          await linkedUser.verifyBeforeUpdateEmail(email);

          return userModel;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }

    return null;
  }
}
