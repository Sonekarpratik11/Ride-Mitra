import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_mitra_new/driver_page/post_a_ride.dart';
import 'package:ride_mitra_new/passenger_page/find_a_ride.dart';

class RideMitraHomeScreen extends StatefulWidget {
  const RideMitraHomeScreen({Key? key}) : super(key: key);

  @override
  State<RideMitraHomeScreen> createState() => _RideMitraHomeScreenState();
}

class _RideMitraHomeScreenState extends State<RideMitraHomeScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _currentPosition = const LatLng(21.1458, 79.0882);
  final TextEditingController _searchController = TextEditingController();
  bool _isDarkMode = true;
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String _darkMapStyle = '';
  String _lightMapStyle = '';
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setMapStyles();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.forward();
    _determinePosition();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Get current location
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    });

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: 15.0),
      ),
    );
  }

  // Map styles
  void _setMapStyles() {
    _darkMapStyle = '''
      [
        {"elementType": "geometry","stylers":[{"color":"#242f3e"}]},
        {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
        {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
        {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
        {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
        {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
        {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]}
      ]
    ''';
    _lightMapStyle = '''
      [
        {"elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
        {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
        {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
        {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#aadaff"}]},
        {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#d7f7d7"}]}
      ]
    ''';
  }

  // Toggle map theme
  Future<void> _toggleTheme() async {
    final GoogleMapController controller = await _controller.future;
    setState(() => _isDarkMode = !_isDarkMode);
    controller.setMapStyle(_isDarkMode ? _darkMapStyle : _lightMapStyle);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _isDarkMode
        ? const Color(0xFF00E676)
        : Colors.green;
    final Color secondaryColor = _isDarkMode
        ? const Color(0xFF69F0AE)
        : Colors.lightGreenAccent;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              controller.setMapStyle(
                _isDarkMode ? _darkMapStyle : _lightMapStyle,
              );
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 13.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            padding: const EdgeInsets.only(
              bottom: 100,
              right: 6,
            ), // shifts zoom buttons up
          ),

          // UI Overlay
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Colors.greenAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RideMitra',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: _isDarkMode ? Colors.white70 : Colors.grey,
                        ),
                        hintText: "Where to?",
                        hintStyle: TextStyle(
                          color: _isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Buttons
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildRideButton(
                          "Find Ride",
                          primaryColor,
                          secondaryColor,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FindRideScreen(),
                              ),
                            );
                          },
                        ),
                        _buildRideButton(
                          "Offer Ride",
                          Colors.blueAccent,
                          Colors.lightBlueAccent,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostRideScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 70),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Buttons (theme + location)
          Positioned(
            right: 15,
            bottom: 500,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "theme",
                  onPressed: _toggleTheme,
                  backgroundColor: _isDarkMode ? Colors.amber : Colors.black87,
                  child: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "location",
                  onPressed: _determinePosition,
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _isDarkMode
            ? Colors.black.withOpacity(0.9)
            : Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_taxi),
            label: 'My Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Ride Buttons
  Widget _buildRideButton(
    String text,
    Color startColor,
    Color endColor,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(colors: [startColor, endColor]),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
