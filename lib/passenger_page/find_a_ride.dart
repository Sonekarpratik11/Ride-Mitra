import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_place/google_place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const kGoogleApiKey = "AIzaSyAB_F4Y_wEX_RMqOIwDKDHJcAtMi7aY2N4";
final GooglePlace googlePlace = GooglePlace(kGoogleApiKey);

class FindRideScreen extends StatefulWidget {
  @override
  _FindRideScreenState createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  String? fromLocation;
  LatLng? fromLatLng;
  String? toLocation;
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  List<DocumentSnapshot> matchingRides = [];
  bool isLoading = false;

  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location services are disabled.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location permission denied")),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          fromLatLng = LatLng(position.latitude, position.longitude);
          fromLocation = "${placemark.name}, ${placemark.locality}, ${placemark.administrativeArea}";
        });
      }
    } catch (e) {
      print("Location Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location")),
      );
    }
  }

  Future<void> selectLocation(bool isFrom) async {
    TextEditingController searchController = TextEditingController();
    List<AutocompletePrediction> predictions = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: "Search location",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) async {
                    if (value.isNotEmpty) {
                      var result = await googlePlace.autocomplete.get(value);
                      setModalState(() {
                        predictions = result?.predictions ?? [];
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                if (isFrom)
                  ListTile(
                    leading: Icon(Icons.my_location, color: Colors.indigo),
                    title: Text("Use My Current Location"),
                    onTap: () async {
                      Navigator.pop(context);
                      await getCurrentLocation();
                    },
                  ),
                ...predictions.map((e) => ListTile(
                  title: Text(e.description ?? ""),
                  onTap: () async {
                    final details = await googlePlace.details.get(e.placeId!);
                    final loc = details?.result?.geometry?.location;
                    if (loc != null) {
                      setState(() {
                        if (isFrom) {
                          fromLocation = e.description;
                          fromLatLng = LatLng(loc.lat!, loc.lng!);
                        } else {
                          toLocation = e.description;
                        }
                      });
                    }
                    Navigator.pop(context);
                  },
                ))
              ],
            ),
          ),
        ),
      ),
    );
  }

  void searchRides() async {
    if (fromLocation == null || toLocation == null || dateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill From, To & Date')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('rides')
          .where('date', isEqualTo: dateController.text.trim())
          .get();

      final filtered = result.docs.where((doc) {
        final docFrom = (doc['from'] as String).toLowerCase();
        final docTo = (doc['to'] as String).toLowerCase();
        return docFrom.contains(fromLocation!.toLowerCase()) &&
            docTo.contains(toLocation!.toLowerCase());
      }).toList();

      setState(() {
        matchingRides = filtered;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> bookRide(DocumentSnapshot ride) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login required")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'rideId': ride.id,
        'passengerId': user.uid,
        'driverId': ride['uid'],
        'from': ride['from'],
        'fromLatLng': fromLatLng != null ? GeoPoint(fromLatLng!.latitude, fromLatLng!.longitude) : null,
        'to': ride['to'],
        'date': ride['date'],
        'time': ride['time'],
        'fare': ride['fare'],
        'status': 'pending',
        'bookedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ride booked successfully")),
      );
    } catch (e) {
      print("Booking error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to book ride")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: Text("Find a Ride"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Plan your ride", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
            SizedBox(height: 12),
            buildLocationTile("From", fromLocation, () => selectLocation(true)),
            buildLocationTile("To", toLocation, () => selectLocation(false)),
            SizedBox(height: 12),
            buildDateTimePicker(dateController, "Date", Icons.calendar_today, () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                dateController.text = "${picked.day}/${picked.month}/${picked.year}";
              }
            }),
            SizedBox(height: 12),
            buildDateTimePicker(timeController, "Time (optional)", Icons.access_time, () async {
              final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (picked != null) {
                timeController.text = picked.format(context);
              }
            }),
            SizedBox(height: 20),
            if (fromLatLng != null)
              SizedBox(
                height: 150,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: fromLatLng!, zoom: 14),
                  markers: {
                    Marker(
                      markerId: MarkerId("fromMarker"),
                      position: fromLatLng!,
                      infoWindow: InfoWindow(title: "From Location"),
                    )
                  },
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: searchRides,
              icon: Icon(Icons.search),
              label: Text("Search Rides", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (matchingRides.isNotEmpty)
              ...matchingRides.map((ride) => buildRideCard(ride)).toList()
            else
              Center(child: Text("No rides found", style: TextStyle(color: Colors.grey[600]))),
          ],
        ),
      ),
    );
  }

  Widget buildDateTimePicker(TextEditingController controller, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.indigo),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget buildLocationTile(String label, String? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.indigo),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? "Select $label location",
                style: TextStyle(fontSize: 16, color: value == null ? Colors.grey : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRideCard(DocumentSnapshot ride) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("From: ${ride['from']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text("To: ${ride['to']}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text("Date: ${ride['date']} at ${ride['time']}"),
            Text("Fare: ₹${ride['fare']} | Seats: ${ride['seatsAvailable']}"),
            Text("Driver: ${ride['phoneNumber'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => bookRide(ride),
                icon: Icon(Icons.check_circle_outline),
                label: Text("Book Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
