import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ride_mitra_new/driver_page/ride_posted_screen.dart';
import '../role_selection_screen.dart';

const kGoogleApiKey = "AIzaSyAB_F4Y_wEX_RMqOIwDKDHJcAtMi7aY2N4";
final GooglePlace googlePlace = GooglePlace(kGoogleApiKey);

class PostRideScreen extends StatefulWidget {
  @override
  _PostRideScreenState createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final fareController = TextEditingController();
  final seatsController = TextEditingController();

  String? fromLocation;
  String? toLocation;
  LatLng? fromLatLng;
  LatLng? toLatLng;

  GoogleMapController? mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission is required')),
          );
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      fromLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        fromLocation = "Current Location";
        _markers.add(
          Marker(
            markerId: MarkerId("from"),
            position: fromLatLng!,
            infoWindow: InfoWindow(title: "Current Location"),
          ),
        );
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(fromLatLng!, 14),
      );

      _updateRoute();
    } catch (e) {
      print("Error fetching location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  Future<void> selectLocation(bool isFrom) async {
    final searchController = TextEditingController();
    List<AutocompletePrediction> predictions = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFrom)
                  ListTile(
                    leading: Icon(Icons.my_location),
                    title: Text("Use current location"),
                    onTap: () {
                      Navigator.pop(context);
                      getCurrentLocation();
                    },
                  ),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: "Search location",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.isNotEmpty) {
                      final result = await googlePlace.autocomplete.get(value);
                      setModalState(() {
                        predictions = result?.predictions ?? [];
                      });
                    }
                  },
                ),
                SizedBox(height: 10),
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
                          toLatLng = LatLng(loc.lat!, loc.lng!);
                        }
                      });
                      _updateRoute();
                      Navigator.pop(context);
                    }
                  },
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateRoute() async {
    if (fromLatLng == null || toLatLng == null) return;

    try {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        kGoogleApiKey,
        PointLatLng(fromLatLng!.latitude, fromLatLng!.longitude),
        PointLatLng(toLatLng!.latitude, toLatLng!.longitude),
      );

      List<LatLng> points = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

      _polylines = {
        Polyline(
          polylineId: PolylineId("route"),
          points: points,
          width: 5,
          color: Colors.indigo,
        )
      };

      _markers = {
        Marker(markerId: MarkerId('from'), position: fromLatLng!),
        Marker(markerId: MarkerId('to'), position: toLatLng!),
      };

      mapController?.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
              fromLatLng!.latitude <= toLatLng!.latitude
                  ? fromLatLng!.latitude
                  : toLatLng!.latitude,
              fromLatLng!.longitude <= toLatLng!.longitude
                  ? fromLatLng!.longitude
                  : toLatLng!.longitude),
          northeast: LatLng(
              fromLatLng!.latitude >= toLatLng!.latitude
                  ? fromLatLng!.latitude
                  : toLatLng!.latitude,
              fromLatLng!.longitude >= toLatLng!.longitude
                  ? fromLatLng!.longitude
                  : toLatLng!.longitude),
        ),
        100,
      ));

      setState(() {});
    } catch (e) {
      print("Error drawing route: $e");
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      dateController.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      timeController.text = picked.format(context);
    }
  }

  Future<void> postRide() async {
    final user = FirebaseAuth.instance.currentUser;

    if (fromLocation == null ||
        toLocation == null ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        fareController.text.isEmpty ||
        seatsController.text.isEmpty ||
        user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('rides').add({
        'uid': user.uid,
        'from': fromLocation,
        'to': toLocation,
        'fromLat': fromLatLng?.latitude,
        'fromLng': fromLatLng?.longitude,
        'toLat': toLatLng?.latitude,
        'toLng': toLatLng?.longitude,
        'date': dateController.text,
        'time': timeController.text,
        'fare': int.tryParse(fareController.text) ?? 0,
        'seatsAvailable': int.tryParse(seatsController.text) ?? 0,
        'createdAt': Timestamp.now(),
        'phoneNumber': user.phoneNumber ?? '',
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RidePostedScreen(
            fromLocation: fromLocation!,
            toLocation: toLocation!,
            date: dateController.text,
            time: timeController.text,
            seats: seatsController.text,
          ),
        ),
      );
    } catch (e) {
      print("Error posting ride: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context); // back navigation
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Post a Ride"),
          backgroundColor: Colors.indigo,
          leading: BackButton(
            onPressed: () {
              Navigator.pop(context); // back navigation
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text("Post your ride", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              buildLocationSelector("From", fromLocation, () => selectLocation(true)),
              SizedBox(height: 12),
              buildLocationSelector("To", toLocation, () => selectLocation(false)),
              SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: GoogleMap(
                  onMapCreated: (controller) => mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: fromLatLng ?? LatLng(20.5937, 78.9629),
                    zoom: 5,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                ),
              ),
              SizedBox(height: 12),
              buildDatePicker(),
              SizedBox(height: 12),
              buildTimePicker(),
              SizedBox(height: 12),
              buildTextField(fareController, "Fare", Icons.currency_rupee, TextInputType.number),
              SizedBox(height: 12),
              buildTextField(seatsController, "Seats", Icons.event_seat, TextInputType.number),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: postRide,
                icon: Icon(Icons.send),
                label: Text("Post Ride"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLocationSelector(String label, String? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
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

  Widget buildTextField(TextEditingController controller, String label, IconData icon,
      [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget buildDatePicker() {
    return GestureDetector(
      onTap: pickDate,
      child: AbsorbPointer(
        child: TextField(
          controller: dateController,
          decoration: InputDecoration(
            labelText: "Date",
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget buildTimePicker() {
    return GestureDetector(
      onTap: pickTime,
      child: AbsorbPointer(
        child: TextField(
          controller: timeController,
          decoration: InputDecoration(
            labelText: "Time",
            prefixIcon: Icon(Icons.access_time),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
