import 'package:flutter/material.dart';
import 'package:bhabi/services/auth_service.dart';

class LoginPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          child: Text('Sign In Anonymously'),
          onPressed: () async {
            final uid = await _authService.signInAnonymously();
            if (uid != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Signed in! UID: $uid')),
              );
            }
          },
        ),
      ),
    );
  }
}