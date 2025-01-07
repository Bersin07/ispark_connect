import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workspace/components/theme_provider.dart';

class ForgotPwPage extends StatefulWidget {
  const ForgotPwPage({super.key});

  @override
  State<ForgotPwPage> createState() => _ForgotPwPageState();
}

class _ForgotPwPageState extends State<ForgotPwPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Password reset
  Future<void> passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text("Password reset link sent! Please check your mail"),
            backgroundColor: const Color(0xFF009688),
            contentTextStyle: const TextStyle(color: Colors.white),
            actions: [
              TextButton(
                child: const Text('OK', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(e.message.toString()),
            backgroundColor: const Color(0xFF009688),
            contentTextStyle: const TextStyle(color: Colors.white),
            actions: [
              TextButton(
                child: const Text('OK', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? Color(0xFF009688) : const Color(0xFF009688),
        elevation: 0,
        title: Text(
          "Reset your password",
          style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.white),
        ),
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.black : const Color(0xFFFAFAFA),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              "Enter your Email and we will send a password reset link",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFFFC107)),
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Email',
                hintStyle: TextStyle(color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[800]),
                fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                filled: true,
              ),
              style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(height: 10),
          MaterialButton(
            onPressed: passwordReset,
            child: const Text(
              "Reset Password",
              style: TextStyle(color: Colors.white),
            ),
            color: const Color(0xFF009688),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
