import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:workspace/auth/main_page.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        child: Image.asset('assets/animation/logo.png'),
      ),
      nextScreen: MainPage(),
      duration: 3500,
      backgroundColor: Colors.white,
    );
  }
}
