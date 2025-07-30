import 'package:flutter/material.dart';
import 'package:ride_mitra_new/driver_page/my_ride_screen.dart';
import '../role_selection_screen.dart';

class RidePostedScreen extends StatelessWidget {
  final String fromLocation;
  final String toLocation;
  final String date;
  final String time;
  final String seats;

  const RidePostedScreen({
    Key? key,
    required this.fromLocation,
    required this.toLocation,
    required this.date,
    required this.time,
    required this.seats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
              (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.indigo[50],
        appBar: AppBar(
          title: const Text("Ride Posted"),
          backgroundColor: Colors.indigo,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.teal, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Your ride has been successfully posted!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                buildDetailRow("From", fromLocation),
                buildDetailRow("To", toLocation),
                buildDetailRow("Date", date),
                buildDetailRow("Time", time),
                buildDetailRow("Seats", seats),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text("Back to Home"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DriverMyRidesScreen()),
                    );
                  },
                  icon: const Icon(Icons.directions_car),
                  label: const Text("View My Rides"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
