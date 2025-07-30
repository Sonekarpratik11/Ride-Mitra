import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:ride_mitra_new/driver_page/post_a_ride.dart';

class DriverProfileSetup extends StatefulWidget {
  @override
  _DriverProfileSetupState createState() => _DriverProfileSetupState();
}

class _DriverProfileSetupState extends State<DriverProfileSetup> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final vehicleTypeController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  File? licenseFile;
  File? aadharFile;

  bool isLoading = false;

  final List<Map<String, dynamic>> vehicleOptions = [
    {'label': 'Bike', 'icon': Icons.two_wheeler},
    {'label': 'Car', 'icon': Icons.directions_car},
    {'label': 'Rikshaw', 'icon': Icons.electric_rickshaw},
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> pickFile(bool isLicense) async {
    final XFile? result = await openFile();
    if (result != null && result.path.isNotEmpty) {
      setState(() {
        final selectedFile = File(result.path);
        if (isLicense) {
          licenseFile = selectedFile;
        } else {
          aadharFile = selectedFile;
        }
      });
    }
  }

  Future<String> uploadFile(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> saveDriverProfile() async {
    if (!_formKey.currentState!.validate() || licenseFile == null || aadharFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields & upload documents")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final licenseUrl = await uploadFile(licenseFile!, 'drivers/${user.uid}/license');
      final aadharUrl = await uploadFile(aadharFile!, 'drivers/${user.uid}/aadhar');

      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).set({
        'uid': user.uid,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'vehicleType': vehicleTypeController.text.trim(),
        'vehicleNumber': vehicleNumberController.text.trim(),
        'licenseUrl': licenseUrl,
        'aadharUrl': aadharUrl,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile saved successfully")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PostRideScreen()),
      );
    } catch (e) {
      print("Save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save profile")));
    }

    setState(() => isLoading = false);
  }

  Widget buildFileTile(String label, File? file, VoidCallback onTap) {
    return ListTile(
      title: Text(file != null ? file.path.split('/').last : 'Upload $label'),
      leading: Icon(Icons.upload_file, color: Colors.indigo),
      trailing: Icon(Icons.attach_file),
      onTap: onTap,
    );
  }

  Widget buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value == null || value.trim().isEmpty ? "Required" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: Text("Driver Profile Setup"),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Complete your driver profile",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
              SizedBox(height: 20),

              buildTextField(nameController, "Full Name", Icons.person),
              SizedBox(height: 15),

              buildTextField(phoneController, "Phone Number", Icons.phone,
                  enabled: true, keyboardType: TextInputType.phone),
              SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: vehicleTypeController.text.isNotEmpty ? vehicleTypeController.text : null,
                decoration: InputDecoration(
                  labelText: "Vehicle Type",
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: vehicleOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option['label'],
                    child: Row(
                      children: [
                        Icon(option['icon'], size: 20),
                        SizedBox(width: 10),
                        Text(option['label']),
                      ],
                    ),
                  );
                }).toList(),
                validator: (value) => value == null || value.isEmpty ? "Select vehicle type" : null,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => vehicleTypeController.text = value);
                  }
                },
              ),

              SizedBox(height: 15),
              buildTextField(vehicleNumberController, "Vehicle Number", Icons.confirmation_number),
              SizedBox(height: 20),

              Divider(),
              Text("Upload Documents", style: TextStyle(fontWeight: FontWeight.w600)),
              buildFileTile("Driving License", licenseFile, () => pickFile(true)),
              buildFileTile("Aadhar Card", aadharFile, () => pickFile(false)),
              Divider(),

              SizedBox(height: 25),
              isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveDriverProfile,
                  icon: Icon(Icons.save),
                  label: Text("Save Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

