import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    final locations = Provider.of<LocationProvider>(context).locations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (locations.isNotEmpty)
              DropdownButton<String>(
                hint: const Text('Select Location'),
                value: _selectedLocation,
                onChanged: (newValue) {
                  setState(() {
                    _selectedLocation = newValue;
                  });
                },
                items: locations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location['name'],
                    child: Text(location['name']),
                  );
                }).toList(),
              ),
            ElevatedButton(
              child: const Text('Check In'),
              onPressed: () async {
                if (_selectedLocation != null) {
                  final selectedLocation = locations
                      .firstWhere((loc) => loc['name'] == _selectedLocation);
                  final currentLocation = await Provider.of<LocationProvider>(
                          context,
                          listen: false)
                      .getCurrentLocation();

                  final isWithinDistance =
                      Provider.of<LocationProvider>(context, listen: false)
                          .isWithinDistance(
                    currentLocation.latitude,
                    currentLocation.longitude,
                    selectedLocation['latitude'],
                    selectedLocation['longitude'],
                    50,
                  );

                  if (isWithinDistance) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Success"),
                          content:
                              const Text("Attendance recorded successfully!"),
                          actions: [
                            TextButton(
                              child: const Text('Ok'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Failed"),
                          content:
                              const Text("You are too far from the location!"),
                          actions: [
                            TextButton(
                              child: const Text('Ok'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
