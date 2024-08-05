import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'package:collection/collection.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _nameController = TextEditingController();
  LatLng? _pickedLocation;

  void _selectLocation(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers =
        Provider.of<LocationProvider>(context, listen: false).getLocations();
    final markerSet = markers.mapIndexed(
      (index, marker) {
        return Marker(
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: marker['name'],
          ),
          markerId: MarkerId(marker['name'].toString() + index.toString()),
          position: LatLng(marker['latitude'], marker['longitude']),
        );
      },
    ).toSet();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Location'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Location Name'),
          ),
          FutureBuilder(
              future: getCurrentLocation(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text("Google Map Error.");
                if (!snapshot.hasData) {
                  return const Text("Getting current location...");
                }
                return SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(snapshot.data?.latitude as double,
                          snapshot.data?.longitude as double),
                      zoom: 16,
                    ),
                    onTap: _selectLocation,
                    markers: {
                      ...markerSet,
                      ...((_pickedLocation == null
                          ? {}
                          : {
                              Marker(
                                markerId: const MarkerId('m1'),
                                position: _pickedLocation!,
                              )
                            })),
                    },
                  ),
                );
              }),
          ElevatedButton(
            child: const Text('Save Location'),
            onPressed: () {
              if (_nameController.text.isNotEmpty && _pickedLocation != null) {
                Provider.of<LocationProvider>(context, listen: false)
                    .addLocation(
                  _nameController.text,
                  _pickedLocation!.latitude,
                  _pickedLocation!.longitude,
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<LatLng> getCurrentLocation() async {
    final markers =
        Provider.of<LocationProvider>(context, listen: false).getLocations();

    if (markers.isEmpty) {
      final location =
          await Provider.of<LocationProvider>(context, listen: false)
              .getCurrentLocation();
      return LatLng(location.latitude, location.longitude);
    }
    var latt = 0.0, lon = 0.0;

    for (var marker in markers) {
      latt += marker['latitude'] ?? 0;
      lon += marker['longitude'] ?? 0;
    }
    latt /= markers.length;
    lon /= markers.length;
    return LatLng(latt, lon);
  }
}
