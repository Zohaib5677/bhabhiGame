import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  final String roomCode;

  const GameScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game Room: $roomCode')),
      body: const Center(child: Text('Game in progress...Zohaib')),
    );
  }
}
