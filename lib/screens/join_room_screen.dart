import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'lobby_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Game Room')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Enter Room Code',
                border: OutlineInputBorder(),
              ),
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _joinRoom(context),
              child: const Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinRoom(BuildContext context) async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-character room code')),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    try {
      await _firebaseService.joinGameRoom(code, name);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyScreen(roomCode: code, isHost: false),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join room: $e')),
      );
    }
  }
}
