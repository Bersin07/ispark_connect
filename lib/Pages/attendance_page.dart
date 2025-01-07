import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final user = FirebaseAuth.instance.currentUser!;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _selectedCheckIn;
  Map<String, dynamic>? _selectedCheckOut;

  @override
  void initState() {
    super.initState();
  }

  // Fetches events for the selected day from Firestore
  Future<void> _fetchEventsForDay(DateTime day) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedCheckIn = null;
      _selectedCheckOut = null;
    });

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userID = user.uid;

      // Convert the day to a timestamp range for querying Firestore
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      // Fetch check-in data
      var checkInSnapshot = await firestore
          .collection('users')
          .doc(userID)
          .collection('check_ins')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get();

      if (checkInSnapshot.docs.isNotEmpty) {
        _selectedCheckIn = checkInSnapshot.docs.first.data();
        _selectedCheckIn!['timestamp'] = checkInSnapshot.docs.first['timestamp'].toDate();
      }

      // Fetch check-out data
      var checkOutSnapshot = await firestore
          .collection('users')
          .doc(userID)
          .collection('check_outs')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get();

      if (checkOutSnapshot.docs.isNotEmpty) {
        _selectedCheckOut = checkOutSnapshot.docs.first.data();
        _selectedCheckOut!['timestamp'] = checkOutSnapshot.docs.first['timestamp'].toDate();
      }

      setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch events: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _fetchEventsForDay(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Attendance',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF009688),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF009688),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.bottomCenter,
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF009688)),
                rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF009688)),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (day.weekday == DateTime.sunday) {
                    return Center(
                      child: Text(
                        day.day.toString(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20), // Add some space between calendar and details
            if (_selectedDay == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Text(
                    'Pick a date',
                    style: TextStyle(color: Color(0xFF009688), fontSize: 20),
                  ),
                ),
              )
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                ),
              )
            else if (_selectedCheckIn == null && _selectedCheckOut == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Text(
                    'Not attended',
                    style: TextStyle(color: Colors.red, fontSize: 20),
                  ),
                ),
              )
            else
              _buildEventDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (_selectedCheckIn != null) ...[
          const Text(
            'Check-In:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          _buildEventDetailItem(_selectedCheckIn!),
          const SizedBox(height: 10),
        ],
        if (_selectedCheckOut != null) ...[
          const Text(
            'Check-Out:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          _buildEventDetailItem(_selectedCheckOut!),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildEventDetailItem(Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(
            'Location: ${event['address']}',
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            'Latitude: ${event['latitude']}, Longitude: ${event['longitude']}\n'
            'Time: ${event['timestamp']}',
          ),
          leading: Icon(
            event['type'] == 'checkIn' ? Icons.login : Icons.logout,
            color: event['type'] == 'checkIn' ? const Color(0xFF009688) : Colors.red,
          ),
        ),
      ),
    );
  }
}
