import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user UID
  String? get currentUserUid => _auth.currentUser?.uid;

  // Stream of User (auth state changes)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Anonymous sign-in with detailed error handling
  Future<String?> signInAnonymously() async {
    try {
      // Check if already signed in
      if (_auth.currentUser != null) {
        await signOut(); // Sign out first to ensure clean state
      }
      
      final UserCredential result = await _auth.signInAnonymously();
      final String? uid = result.user?.uid;
      
      if (uid != null) {
        print("Anonymous sign-in successful: $uid");
        return uid;
      } else {
        print("Anonymous sign-in failed: No UID returned");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth error during anonymous sign-in: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Unexpected error during anonymous sign-in: $e");
      return null;
    }
  }

  // Google Sign-In with detailed error handling
  Future<String?> signInWithGoogle() async {
    try {
      // Check if already signed in and sign out for clean state
      if (_auth.currentUser != null) {
        await signOut();
      }
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // If user cancels the sign-in
      if (googleUser == null) {
        print("Google sign-in cancelled by user");
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Verify we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print("Google sign-in failed: Missing authentication tokens");
        return null;
      }

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final String? uid = userCredential.user?.uid;
      
      if (uid != null) {
        print("Google sign-in successful: $uid");
        return uid;
      } else {
        print("Google sign-in failed: No UID returned");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth error during Google sign-in: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Unexpected error during Google sign-in: $e");
      return null;
    }
  }

  // Sign out with error handling
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
      print("Sign out successful");
    } catch (e) {
      print("Error during sign out: $e");
      // Don't throw - signing out should be graceful
    }
  }

  // Get current user info
  User? get currentUser => _auth.currentUser;
  
  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;
}