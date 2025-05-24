// screens/create_room_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import 'lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedPlayerCount = 2; // Default to 2 players

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Game Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Select number of players:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Slider(
              value: _selectedPlayerCount.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              label: _selectedPlayerCount.toString(),
              onChanged: (value) {
                setState(() {
                  _selectedPlayerCount = value.toInt();
                });
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _createRoom(context),
              child: const Text('Create Room'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testDeckApi,
              child: const Text('Test Deck API'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRoom(BuildContext context) async {
    try {
      final roomCode = await _firebaseService.createGameRoom(_selectedPlayerCount);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LobbyScreen(roomCode: roomCode, isHost: true),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $e')),
      );
    }
  }

  Future<void> _testDeckApi() async {
    try {
      final shuffleResponse = await http.get(
        Uri.parse('https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1'),
      );
      print('🔄 Shuffle API response: ${shuffleResponse.body}');

      if (shuffleResponse.statusCode != 200) {
        print('❌ Failed to create and shuffle deck');
        return;
      }

      final shuffleData = json.decode(shuffleResponse.body);
      final deckId = shuffleData['deck_id'];
      print('🆔 Deck ID: $deckId');

      final drawResponse = await http.get(
        Uri.parse('https://deckofcardsapi.com/api/deck/$deckId/draw/?count=5'),
      );
      print('🃏 Draw Cards API response: ${drawResponse.body}');

      if (drawResponse.statusCode != 200) {
        print('❌ Failed to draw cards');
        return;
      }

      final drawData = json.decode(drawResponse.body);
      print('🎴 Cards drawn: ${drawData['cards']}');
    } catch (e) {
      print('❗ Error testing Deck of Cards API: $e');
    }
  }
}
