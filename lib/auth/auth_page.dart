import 'package:flutter/material.dart';
import 'package:workspace/Pages/login_page.dart';
import 'package:workspace/Pages/register_page.dart.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {

  //initially show the login page
  bool showLoginPage = true;


  void toogleScreens(){
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (showLoginPage){
      return LoginPage(
        showRegisterPage: toogleScreens
        );

    }else{
      return RegisterPage(showLoginPage: toogleScreens);
    }
  }
}