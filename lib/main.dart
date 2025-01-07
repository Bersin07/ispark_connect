import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workspace/components/theme_provider.dart';
import 'package:workspace/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBch_zvyH8gkzcKob0PyafpdMoeuRsX-9Y",
            authDomain: "workspace-a0f77.firebaseapp.com",
            projectId: "workspace-a0f77",
            storageBucket: "workspace-a0f77.appspot.com",
            messagingSenderId: "12338909234",
            appId: "1:12338909234:web:9a1dc16b3b93c1f8bdec2b",
            measurementId: "G-57R0E0V0BT"));
  } else {
    await Firebase.initializeApp();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: SplashScreen(),
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('live_location')
            .add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("Error updating location in background: $e");
      }
    }
    return Future.value(true);
  });
}
