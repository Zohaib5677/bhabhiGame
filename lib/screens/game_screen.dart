import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import '../services/firebase_service.dart';

class GameScreen extends StatefulWidget {
  final String roomCode;

  const GameScreen({super.key, required this.roomCode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FirebaseService _firebase = FirebaseService();
  final user = FirebaseAuth.instance.currentUser!;
  late Stream<DocumentSnapshot> roomStream;

  @override
  void initState() {
    super.initState();
    roomStream = _firebase.getRoomStream(widget.roomCode);
  }

  void _playCard(CardModel card) {
    _firebase.playCard(widget.roomCode, card);
  }

  void _swapHand() async {
    try {
      await _firebase.swapHands(widget.roomCode);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Game Room: ${widget.roomCode}"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final players = List<String>.from(data['players'] ?? []);
          final playerNames = Map<String, String>.from(data['playerNames'] ?? {});
          final currentTurnIndex = data['currentTurn'] ?? 0;
          final bool isMyTurn = players[currentTurnIndex % players.length] == user.uid;
          final Map<String, dynamic> playerCardsJson = data['playerCards'] ?? {};
          final List<dynamic> playedCardsJson = data['playedCards'] ?? [];

          // Parse current user's hand
          List<CardModel> currentUserHand = [];
          if (playerCardsJson[user.uid] != null) {
            currentUserHand = (playerCardsJson[user.uid] as List)
                .map((card) => CardModel.fromJson(card))
                .toList();
          }

          // Parse played cards
          List<CardModel> playedCards = playedCardsJson
              .map((card) => CardModel.fromJson(card))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Turn Indicator
                Text(
                  isMyTurn ? "It's Your Turn!" : "Waiting for Opponent...",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Played Cards
                PlayedCardsRow(cards: playedCards),
                const SizedBox(height: 30),

                // Your Hand
                Text("Your Hand", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),

                // Hand Grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2 / 3,
                    ),
                    itemCount: currentUserHand.length,
                    itemBuilder: (context, index) {
                      final card = currentUserHand[index];
                      return GestureDetector(
                        onTap: isMyTurn ? () => _playCard(card) : null,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(card.image, height: 80),
                              Text("${card.value} of ${card.suit}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isMyTurn && data['playedCards'].isEmpty
                          ? _swapHand
                          : null,
                      icon: const Icon(Icons.sync_alt),
                      label: const Text("Swap Hand"),
                    ),
                    ElevatedButton.icon(
                      onPressed: isMyTurn ? () {} : null,
                      icon: const Icon(Icons.flag),
                      label: const Text("End Turn"),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===== WIDGETS =====

class PlayedCardsRow extends StatelessWidget {
  final List<CardModel> cards;

  const PlayedCardsRow({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: cards.map((card) {
        return Chip(label: Text("${card.value} of ${card.suit}"));
      }).toList(),
    );
  }
}