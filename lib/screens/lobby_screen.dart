// screens/lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:flutter/services.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;

  const LobbyScreen({super.key, required this.roomCode, required this.isHost});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomCode}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () => _copyCodeToClipboard(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firebaseService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Room not found'));
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final players = List<String>.from(roomData['players'] ?? []);
          final maxPlayers = roomData['maxPlayers'] ?? 6; // Default to 6 if not set

          return Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Players (${players.length}/$maxPlayers)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(players[index]),
                  ),
                ),
              ),
              if (widget.isHost)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: players.length >= 2 ? _startGame : null,
                    child: const Text('Start Game'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _copyCodeToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Room code copied to clipboard')),
    );
  }

  void _startGame() {
    _firebaseService.startGame(widget.roomCode);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(roomCode: widget.roomCode)),
    );
  }
}