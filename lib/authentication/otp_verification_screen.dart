import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ride_mitra_new/homescreen/homescreen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPVerificationScreen({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;

  void _verifyOTP() async {
    setState(() => _isVerifying = true);

    try {
      // Step 1: Create credential from OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      // Step 2: Sign in the user
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Step 3: Save user info to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'phone': user.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Step 4: Navigate to Role Selection Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RideMitraHomeScreen()),
        );
      } else {
        throw Exception("User is null after sign-in.");
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP Verification Failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "OTP sent to +91 ${widget.phoneNumber}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isVerifying
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOTP,
                    child: Text("Verify OTP"),
                  ),
          ],
        ),
      ),
    );
  }
}
