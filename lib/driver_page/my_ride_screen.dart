import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverMyRidesScreen extends StatefulWidget {
  @override
  _DriverMyRidesScreenState createState() => _DriverMyRidesScreenState();
}

class _DriverMyRidesScreenState extends State<DriverMyRidesScreen> {
  List<DocumentSnapshot> myPostedRides = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyPostedRides();
  }

  Future<void> fetchMyPostedRides() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final result = await FirebaseFirestore.instance
          .collection('rides')
          .where('uid', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      setState(() {
        myPostedRides = result.docs;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching driver's rides: $e");
      setState(() => isLoading = false);
    }
  }

  Future<List<DocumentSnapshot>> getBookingsForRide(String rideId) async {
    final result = await FirebaseFirestore.instance
        .collection('bookings')
        .where('rideId', isEqualTo: rideId)
        .get();
    return result.docs;
  }

  Future<void> deleteRide(String rideId) async {
    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).delete();
      // Also delete related bookings
      final bookings = await getBookingsForRide(rideId);
      for (var booking in bookings) {
        await booking.reference.delete();
      }
      fetchMyPostedRides();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ride deleted")),
      );
    } catch (e) {
      print("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete ride")),
      );
    }
  }

  Widget buildRideCard(DocumentSnapshot ride) {
    final data = ride.data() as Map<String, dynamic>;

    return FutureBuilder<List<DocumentSnapshot>>(
      future: getBookingsForRide(ride.id),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("From: ${data['from']}", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("To: ${data['to']}"),
                Text("Date: ${data['date']}  •  Time: ${data['time']}"),
                Text("Fare: ₹${data['fare']}"),
                Text("Seats Available: ${data['seatsAvailable']}"),
                SizedBox(height: 8),
                Text("Bookings (${bookings.length}):", style: TextStyle(fontWeight: FontWeight.w600)),
                ...bookings.map((b) {
                  final bdata = b.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.grey[700]),
                        SizedBox(width: 5),
                        Expanded(child: Text("Status: ${bdata['status']}")),
                      ],
                    ),
                  );
                }).toList(),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => deleteRide(ride.id),
                    icon: Icon(Icons.delete_outline, color: Colors.red),
                    label: Text("Delete Ride", style: TextStyle(color: Colors.red)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Posted Rides"),
        backgroundColor: Colors.indigo,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : myPostedRides.isEmpty
          ? Center(child: Text("You haven't posted any rides"))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: myPostedRides.length,
        itemBuilder: (context, index) => buildRideCard(myPostedRides[index]),
      ),
    );
  }
}
