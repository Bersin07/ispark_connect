import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workspace/Pages/attendance_page.dart';
import 'package:workspace/Pages/chat_screen.dart';
import 'package:workspace/Pages/dictionary.dart';
import 'package:workspace/Pages/issues.dart';
import 'package:workspace/Pages/leave_request_page.dart';
import 'package:workspace/Pages/request.dart';
import 'package:workspace/components/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  // ignore: unused_field
  String? _locationMessage;
  // ignore: unused_field
  String? _checkInLocation;
  // ignore: unused_field
  String? _checkOutLocation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isCheckedIn = false;
  String _greetingMessage = "Hello, inspiring educator!";

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCheckInStatus();
    _fetchGreetingMessage(); // Fetch the greeting message
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: $e';
      });
    }
  }

  Future<void> _loadCheckInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
    });
  }

  Future<void> _saveCheckInStatus(bool isCheckedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isCheckedIn', isCheckedIn);
  }

  Future<void> _fetchGreetingMessage() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('greetings').get();
      List<String> messages = snapshot.docs.map((doc) => doc['message'] as String).toList();
      
      if (messages.isNotEmpty) {
        setState(() {
          _greetingMessage = (messages..shuffle()).first;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch greeting messages: $e');
      }
    }
  }

  Future<void> _getLocation(String type) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (type == 'checkOut') {
        bool confirmed = await _showConfirmationDialog(
          title: 'Confirm Check-Out',
          content: 'Are you sure you want to check out?',
        );
        if (!confirmed) {
          setState(() {
            _isLoading = false;
            _locationMessage = null;
          });
          return;
        }
      }

      Position position = await _determinePosition();
      String address = await _getAddressFromCoordinates(position);

      String locationMessage =
          'Latitude: ${position.latitude}, Longitude: ${position.longitude}\nAddress: $address';

      await _storeLocation(type, position, address);

      setState(() {
        if (type == 'checkIn') {
          _checkInLocation = locationMessage;
          _isCheckedIn = true;
        } else if (type == 'checkOut') {
          _checkOutLocation = locationMessage;
          _isCheckedIn = false;
        }
        _saveCheckInStatus(_isCheckedIn);
        _showMessageDialog('Location stored successfully!');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showMessageDialog(String message) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeProvider.themeData.dialogBackgroundColor,
          title: Text('Success', style: TextStyle(color: themeProvider.themeData.colorScheme.secondary)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: themeProvider.themeData.colorScheme.secondary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            return AlertDialog(
              backgroundColor: const Color(0xFF009688),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
              content: Text(
                content,
                style: const TextStyle(color: Colors.white),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: themeProvider.themeData.colorScheme.secondary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    'Confirm',
                    style: TextStyle(color: themeProvider.themeData.colorScheme.secondary),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<String> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      } else {
        return "Address not found";
      }
    } catch (e) {
      return "Failed to get address: $e";
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _storeLocation(String type, Position position, String address) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      String userID = user.uid;
      String userEmail = user.email ?? 'Email not available';
      String username = user.displayName ?? 'Username not available';

      String collection = type == 'checkIn' ? 'check_ins' : 'check_outs';

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd').format(now);
      String formattedTime = DateFormat('HH:mm:ss').format(now);

      await firestore.collection('users').doc(userID).collection(collection).add({
        'uid': userID,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'timestamp': FieldValue.serverTimestamp(),
        'date': formattedDate,
        'time': formattedTime,
        'email': userEmail,
        'username': username,
      });

      if (kDebugMode) {
        print('Location stored successfully in Firestore as $type for user $userID!');
      }
    } catch (e) {
      throw Exception('Failed to store location in Firestore: $e');
    }
  }

  Future<void> _signOut() async {
    bool confirmed = await _showConfirmationDialog(
      title: 'Confirm Sign-Out',
      content: 'Are you sure you want to sign out?',
    );
    if (confirmed) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching URL: $e');
      }
    }
  }

  Future<void> _sendSupportEmail() async {
    final String email = 'bersinb@isparklearning.com'; // Replace with the developer's email address
    final String subject = 'Support Request';
    final String body = 'Please describe your issue or request here.';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunch(emailUri.toString())) {
        await launch(emailUri.toString());
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching email client: $e');
      }
    }
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _onItemTapped(int index) {
    if (index == 0 && !_isCheckedIn) {
      _getLocation('checkIn');
    } else if (index == 1 && _isCheckedIn) {
      _getLocation('checkOut');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120.0), // Set your desired height here
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20)
          ),
          child: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.support_agent, color: Colors.white),
              onPressed: _sendSupportEmail,
            ),
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Update with your logo asset path
                    height: 40,
                  ),
                  const SizedBox(height: 5),
                  Flexible(
                    child: Text(
                      _greetingMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF009688),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                onPressed: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.black : const Color(0xFFFAFAFA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUserCard(),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 3 / 2, // Adjusted aspect ratio to reduce card size
              children: [
                _buildCard(
                  title: 'Attendance',
                  icon: Icons.view_day,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const AttendancePage()));
                  },
                ),
                _buildCard(
                  title: 'Leave Request',
                  icon: Icons.gps_off_outlined,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const LeaveRequestPage()));
                  },
                ),
                _buildCard(
                  title: 'Mail',
                  icon: Icons.mail_rounded,
                  onTap: () {
                    _launchURL(
                        'https://sg2plzcpnl505494.prod.sin2.secureserver.net:2096/cpsess1566171090/3rdparty/roundcube/index.php?_task=mail&_mbox=INBOX'); // Update with your webmail URL
                  },
                ),
                _buildCard(
                  title: 'COEMS',
                  icon: Icons.edit_document,
                  onTap: () {
                    _launchURL('http://www.isparkcoems.com/'); // Update with your webmail URL
                  },
                ),
                _buildCard(
                  title: 'Issues',
                  icon: Icons.dangerous_sharp,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const Issues()));
                  },
                ),
                _buildCard(
                  title: 'Request',
                  icon: Icons.send,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const Request()));
                  },
                ),
                _buildCard(
                  title: 'Chat_Bot',
                  icon: Icons.chat_rounded,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>ChatScreen()));
                  },
                ),
                _buildCard(
                  title: 'Dictionary',
                  icon: Icons.menu_book_rounded,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>DictionaryPage()));
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.copyright, color: Color(0xFF009688)),
              title: Text(
                '2021 TamilNadu India, Inc. All Rights Reserved.',
                style: TextStyle(fontSize: 14),
              ),
              // onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.login, color: _isCheckedIn ? Colors.grey : const Color(0xFFFFC107)),
            label: 'Check In',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout, color: !_isCheckedIn ? Colors.grey : const Color(0xFFFFC107)),
            label: 'Check Out',
          ),
        ],
        currentIndex: _isCheckedIn ? 1 : 0,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: const Color(0xFF757575),
      ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF009688),
                  child: Text(
                    user.displayName?.substring(0, 1) ?? '',
                    style: const TextStyle(
                      fontSize: 40.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'Username not available',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009688),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email ?? 'Email not available',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF009688),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Color.fromARGB(255, 56, 53, 46)),
              onPressed: () {
                // Handle edit action
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF009688)), // Adjusted icon size to reduce card size
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // Adjusted text size to reduce card size
            ],
          ),
        ),
      ),
    );
  }
}
