import 'package:flutter/material.dart';
import 'package:bhabi/services/auth_service.dart';

class HomePage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome!'),
            const SizedBox(height: 20),
            Text('Your UID: ${_authService.currentUserUid ?? 'None'}'),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create');
              },
              child: const Text('Create Room'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/join');
              },
              child: const Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}
