import 'package:flutter/material.dart';
import 'package:geolocator_platform_interface/src/models/position.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedLocation;

  Position? currentLocation;

  bool isCurrentLocationLoading = false;

  Set<Polyline> polylines = {};

  Set<Marker> markers = {};

  Set<Circle> circles = {};

  @override
  void initState() {
    super.initState();

    getCurrentLocation();
  }

  GoogleMapController? mapController;

  @override
  Widget build(BuildContext context) {
    final locations = Provider.of<LocationProvider>(context).locations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isCurrentLocationLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading current location...'),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      "Please select the point you want to create attendance at."),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text("Legends:"),
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 0, 0, 255),
                        ),
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Text(": Your selected position."),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.withOpacity(0.75),
                        ),
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Text(
                          ": Area within a 50m radius of your selected position"),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 0, 0),
                        ),
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Text(": Your current position."),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                        ),
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Text(": Line from current to selected position."),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: 300,
                    child: GoogleMap(
                      polylines: polylines,
                      markers: markers,
                      circles: circles,
                      onMapCreated: (mapController) {
                        this.mapController = mapController;
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(currentLocation?.latitude as double,
                            currentLocation?.longitude as double),
                        zoom: 16,
                      ),
                    ),
                  ),
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
                        final selectedLocation = locations.firstWhere(
                            (loc) => loc['name'] == _selectedLocation);

                        final isWithinDistance = Provider.of<LocationProvider>(
                                context,
                                listen: false)
                            .isWithinDistance(
                          currentLocation?.latitude ?? 0,
                          currentLocation?.longitude ?? 0,
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
                                content: const Text(
                                    "Attendance recorded successfully!"),
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
                                content: const Text(
                                    "You are too far from the location!"),
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

                        final currentLatLng = LatLng(
                          currentLocation?.latitude ?? 0,
                          currentLocation?.longitude ?? 0,
                        );
                        final selectedLocationLatLng = LatLng(
                          selectedLocation['latitude'],
                          selectedLocation['longitude'],
                        );
                        final points = [
                          currentLatLng,
                          selectedLocationLatLng,
                        ];

                        setState(
                          () {
                            markers.clear();
                            circles.clear();
                            polylines.clear();
                            circles = {
                              Circle(
                                circleId: const CircleId("currentLoc"),
                                center: selectedLocationLatLng,
                                radius: 50,
                                strokeWidth: 4,
                                strokeColor: Colors.lightBlue.withOpacity(0.75),
                              ),
                            };
                            polylines.add(
                              Polyline(
                                polylineId: const PolylineId(
                                    "diffBetweenCurrentAndSelectedLocation"),
                                points: points,
                              ),
                            );
                            markers.addAll(
                              [
                                Marker(
                                  markerId: const MarkerId("current_location"),
                                  position: currentLatLng,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                  infoWindow: const InfoWindow(
                                    title: "Your Location",
                                  ),
                                ),
                                Marker(
                                  markerId: const MarkerId("selected_location"),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueBlue,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: selectedLocation['name'],
                                  ),
                                  position: selectedLocationLatLng,
                                ),
                              ],
                            );
                            mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: Provider.of<LocationProvider>(context,
                                          listen: false)
                                      .getMiddlePointOfPoints(points),
                                  zoom: 16,
                                ),
                              ),
                            );
                          },
                        );
                        mapController?.showMarkerInfoWindow(
                          const MarkerId("current_location"),
                        );
                        mapController?.showMarkerInfoWindow(
                          const MarkerId("selected_location"),
                        );
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }

  void getCurrentLocation() async {
    setState(() {
      isCurrentLocationLoading = true;
    });
    currentLocation =
        await Provider.of<LocationProvider>(context, listen: false)
            .getCurrentLocation();
    setState(() {
      isCurrentLocationLoading = false;
    });
  }
}
