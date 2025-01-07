import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:workspace/components/theme_provider.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;

  const RegisterPage({Key? key, required this.showLoginPage}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmpasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    if (passwordConfirmed() && emailValid()) {
      try {
        // Create user with email and password
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Update the user's profile with the username
        User? user = userCredential.user;
        if (user != null) {
          await user.updateDisplayName(_usernameController.text.trim());

          // Save additional user information in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'username': _usernameController.text.trim(),
            'email': user.email,
          });

          // Reload the user to get updated profile information
          await user.reload();

          if (mounted) {
            Navigator.pop(context); // Remove the loading dialog
            // Navigate to your home page or show a success message
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          Navigator.pop(context); // Remove the loading dialog
          // Handle error accordingly
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF009688),
                title: const Text(
                  'Error',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  e.message ?? 'An error occurred during registration.',
                  style: const TextStyle(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.pop(context); // Remove the loading dialog
        // Show a message if passwords don't match or email is invalid
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF009688),
              title: const Text(
                'Invalid Input',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Please make sure both passwords match and the email ends with "@isparklearning.com".',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  bool passwordConfirmed() {
    return _passwordController.text.trim() == _confirmpasswordController.text.trim();
  }

  bool emailValid() {
    return _emailController.text.trim().endsWith('@isparklearning.com');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logo.png",
                  height: 80,
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    return const Text('Error loading image');
                  },
                ),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  "Welcome!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 25,
                    color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF009688),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  "Signup to get started with your first task.",
                  style: TextStyle(
                    fontWeight: FontWeight.normal, 
                    fontSize: 15,
                    color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF757575),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                // Username text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Username',
                      hintStyle: const TextStyle(color: Color(0xFF757575)),
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    style: const TextStyle(color: Colors.black), // Set to black for visibility
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                // Email text field
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
                        borderSide: const BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Color(0xFF757575)),
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    style: const TextStyle(color: Colors.black), // Set to black for visibility
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                // Password text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Color(0xFF757575)),
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.black), // Set to black for visibility
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                // Confirm password text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: _confirmpasswordController,
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Confirm Password',
                      hintStyle: const TextStyle(color: Color(0xFF757575)),
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    obscureText: true,
                    style: const TextStyle(color: Colors.black), // Set to black for visibility
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                // Sign up button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: signUp,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009688),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                // Already have an account? Sign In now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already Have an account?",
                      style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.grey[700]),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    GestureDetector(
                      onTap: widget.showLoginPage,
                      child: const Text(
                        'Sign In Now',
                        style: TextStyle(
                          color: Colors.orange, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
