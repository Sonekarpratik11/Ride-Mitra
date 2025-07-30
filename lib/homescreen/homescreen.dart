import 'package:flutter/material.dart';
import '../driver_page/post_a_ride.dart';
import '../passenger_page/find_a_ride.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final tabs = [PostRideScreen(), FindRideScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Post Ride"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Find Ride"),
        ],
      ),
    );
  }
}