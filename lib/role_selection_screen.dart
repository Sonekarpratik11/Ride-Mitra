import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_page/driver_profile_setup.dart';
import 'driver_page/post_a_ride.dart';
import 'passenger_page/find_a_ride.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: const Text("Choose Your Role"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car, size: 100, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text(
                "Welcome to Ride Mitra",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 40),

              // 🔥 I'm a Driver
              RoleCard(
                title: "I'm a Driver",
                icon: Icons.drive_eta,
                color: Colors.deepPurple,
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    final driverDoc = await FirebaseFirestore.instance
                        .collection('drivers')
                        .doc(user.uid)
                        .get();

                    if (driverDoc.exists) {
                      // ✅ Profile already exists
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => PostRideScreen()),
                      );
                    } else {
                      // ❌ No profile → go to setup screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => DriverProfileSetup()),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("User not logged in")),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),

              // 🚕 I'm a Passenger
              RoleCard(
                title: "I'm a Passenger",
                icon: Icons.person,
                color: Colors.teal,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => FindRideScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const RoleCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Text(title, style: const TextStyle(fontSize: 18)),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
