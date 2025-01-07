import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _fromTimeController = TextEditingController();
  final TextEditingController _toTimeController = TextEditingController();
  String _leaveType = 'Full Day'; // Default leave type

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _fromTimeController.dispose();
    _toTimeController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      try {
        final leaveRequest = {
          'name': _nameController.text,
          'reason': _reasonController.text,
          'fromDate': _leaveType == 'Permission' ? null : _fromDateController.text,
          'toDate': _leaveType == 'Permission' ? null : _toDateController.text,
          'leaveType': _leaveType,
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (_leaveType == 'Permission') {
          leaveRequest['fromTime'] = _fromTimeController.text;
          leaveRequest['toTime'] = _toTimeController.text;
        }

        await FirebaseFirestore.instance.collection('leaveRequests').add(leaveRequest);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave request submitted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit leave request')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      setState(() {
        controller.text = formatter.format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leave Request',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF009688),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildTextField(
                  controller: _reasonController,
                  label: 'Reason for Leave',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildDateField(
                  context: context,
                  controller: _fromDateController,
                  label: 'From Date',
                  onTap: _leaveType != 'Permission'
                      ? () => _selectDate(context, _fromDateController)
                      : null,
                  enabled: _leaveType != 'Permission',
                  validator: (value) {
                    if (_leaveType != 'Permission' && (value == null || value.isEmpty)) {
                      return 'Please enter a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildDateField(
                  context: context,
                  controller: _toDateController,
                  label: 'To Date',
                  onTap: _leaveType != 'Permission'
                      ? () => _selectDate(context, _toDateController)
                      : null,
                  enabled: _leaveType != 'Permission',
                  validator: (value) {
                    if (_leaveType != 'Permission' && (value == null || value.isEmpty)) {
                      return 'Please enter a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildLeaveTypeSelector(),
                if (_leaveType == 'Permission') ...[
                  const SizedBox(height: 16.0),
                  _buildTimeField(
                    context: context,
                    controller: _fromTimeController,
                    label: 'From Time',
                    onTap: () => _selectTime(context, _fromTimeController),
                  ),
                  const SizedBox(height: 16.0),
                  _buildTimeField(
                    context: context,
                    controller: _toTimeController,
                    label: 'To Time',
                    onTap: () => _selectTime(context, _toTimeController),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitRequest,
                  child: const Text('Submit Request'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF009688),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF009688)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFFC107)),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateField({required BuildContext context, required TextEditingController controller, required String label, required VoidCallback? onTap, required bool enabled, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF009688)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFFC107)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Color(0xFF009688)),
          onPressed: onTap,
        ),
      ),
      readOnly: true,
      validator: validator,
      enabled: enabled,
    );
  }

  Widget _buildTimeField({required BuildContext context, required TextEditingController controller, required String label, required VoidCallback onTap}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF009688)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFFC107)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time, color: Color(0xFF009688)),
          onPressed: onTap,
        ),
      ),
      readOnly: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a time';
        }
        return null;
      },
    );
  }

  Widget _buildLeaveTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Leave Type', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
        ListTile(
          title: const Text('Full Day'),
          leading: Radio<String>(
            value: 'Full Day',
            groupValue: _leaveType,
            onChanged: (String? value) {
              setState(() {
                _leaveType = value!;
              });
            },
            activeColor: const Color(0xFF009688),
          ),
        ),
        ListTile(
          title: const Text('Half Day'),
          leading: Radio<String>(
            value: 'Half Day',
            groupValue: _leaveType,
            onChanged: (String? value) {
              setState(() {
                _leaveType = value!;
              });
            },
            activeColor: const Color(0xFF009688),
          ),
        ),
        ListTile(
          title: const Text('Permission'),
          leading: Radio<String>(
            value: 'Permission',
            groupValue: _leaveType,
            onChanged: (String? value) {
              setState(() {
                _leaveType = value!;
              });
            },
            activeColor: const Color(0xFF009688),
          ),
        ),
      ],
    );
  }
}
