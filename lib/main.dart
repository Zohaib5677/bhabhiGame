import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bhabi/services/auth_service.dart';
import './screens/home_page.dart';
import './screens/splash_screen.dart';
import './screens/login_screen.dart';
import './screens/create_room_screen.dart';
import './screens/join_room_screen.dart';
import './screens/lobby_screen.dart';
import './screens/game_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(MyApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize Firebase: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bhabhi Card Game',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A1F38),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE94560),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF2A2F4F),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) =>  HomePage(),
        '/create': (context) => CreateRoomScreen(),
        '/join': (context) => JoinRoomScreen(),
        '/lobby': (context) => LobbyScreen(
              roomCode: ModalRoute.of(context)!.settings.arguments as String,
              isHost: false,
            ),
        '/game': (context) => GameScreen(
              roomCode: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
    );
  }
}