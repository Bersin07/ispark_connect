import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workspace/Pages/home_page.dart';
import 'package:workspace/auth/auth_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Debug log to check if auth state changes are detected
          print('Auth state change detected: ${snapshot.connectionState}');
          // User is logged in
          if (snapshot.hasData) {
            print('User is logged in: ${snapshot.data}');
            return HomePage();
          }

          // User is not logged in
          else {
            print('User is not logged in');
            return AuthPage();
          }
        },
      ),
    );
  }
}
