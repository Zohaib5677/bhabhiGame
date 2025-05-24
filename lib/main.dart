import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:bhabi/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './screens/home_page.dart';
import './screens/login_page.dart';
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
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bhabhi Card Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Authentication error: ${snapshot.error}'),
              ),
            );
          }

          return snapshot.hasData ?  HomePage() :  LoginPage();
        },
      ),
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/create': (context) =>  CreateRoomScreen(),
        '/join': (context) =>  JoinRoomScreen(),
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