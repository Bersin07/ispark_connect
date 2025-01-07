import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:workspace/Pages/admin_homepage.dart';
import 'package:workspace/Pages/forgot_pw_page.dart';
import 'package:workspace/Pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:workspace/components/theme_provider.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;

  const LoginPage({Key? key, required this.showRegisterPage}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> signIn() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      Navigator.pop(context);

      // Get the user document from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
      
      // Determine user role
      String? userRole = userDoc['role'];

      if (userRole == 'admin') {
        Navigator.pop(context);
        // Navigate to admin home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  AdminHomePage()),
        );
      } else {
        Navigator.pop(context);
        // Navigate to user home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showErrorMessage(e.code);
    }
  }

  //wrong email message popup
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF009688),
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                Semantics(
                  label: 'iSpark logo',
                  child: Image.asset(
                    "assets/images/logo.png",
                    height: 80,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      return const Text('Error loading image');
                    },
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Semantics(
                  label: 'Welcome Back!',
                  child: Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF009688),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                //email text field
                Semantics(
                  label: 'Email Input Field',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFFFFC107)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.grey[800]),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                      style: const TextStyle(color: Colors.black), // Set to black for visibility
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Semantics(
                  label: 'Password Input Field',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFFFFC107)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.grey[800]),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                      obscureText: true,
                      style: const TextStyle(color: Colors.black), // Set to black for visibility
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Semantics(
                        label: 'Forget your password? link',
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) {
                              return const ForgotPwPage();
                            }));
                          },
                          child: const Text(
                            "Forget your password?",
                            style: TextStyle(
                              color: Color(0xFFFFC107),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                // sign in button
                Semantics(
                  label: 'Sign In Button',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: GestureDetector(
                      onTap: signIn,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009688),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Sign In',
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
                ),
                const SizedBox(
                  height: 20,
                ),
                const SizedBox(
                  height: 20,
                ),
                Semantics(
                  label: "Haven't signed up yet? Register now link",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Haven't signed up yet?",
                        style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.grey[700]),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      GestureDetector(
                        onTap: widget.showRegisterPage,
                        child: const Text(
                          'Register now',
                          style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
