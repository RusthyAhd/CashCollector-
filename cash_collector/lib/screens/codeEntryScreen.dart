import 'package:cash_collector/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccessCodeEntryScreen extends StatefulWidget {
  @override
  _AccessCodeEntryScreenState createState() => _AccessCodeEntryScreenState();
}

class _AccessCodeEntryScreenState extends State<AccessCodeEntryScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isChecking = false;

  Future<bool> _verifyAccessCode(String inputCode) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('admin')
        .doc('config')
        .get();

    final savedCode = snapshot.data()?['accessCode'];
    return savedCode != null && inputCode == savedCode;
  }

  void _onSubmit() async {
    final input = _codeController.text.trim();

    if (input.isEmpty) {
      setState(() => _errorMessage = "Please enter the access code.");
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final isValid = await _verifyAccessCode(input);

    setState(() => _isChecking = false);

    if (isValid) {
     Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoutePage()),
      );// Proceed to app
    } else {
      setState(() => _errorMessage = "Incorrect access code. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Optional: Background Color or Image
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 72, color: Colors.green.shade900),
                  const SizedBox(height: 16),
                  const Text(
                    "Enter Access Code",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "••••••",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    style: const TextStyle(fontSize: 20, letterSpacing: 4),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _onSubmit,
                      child: Text(
                        _isChecking ? "Checking..." : "Verify",
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
