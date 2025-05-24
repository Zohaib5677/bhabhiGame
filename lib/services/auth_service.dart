import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user UID
  String? get currentUserUid => _auth.currentUser?.uid;

  // Anonymous sign-in
  Future<String?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user?.uid;
    } catch (e) {
      print("Error signing in anonymously: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}