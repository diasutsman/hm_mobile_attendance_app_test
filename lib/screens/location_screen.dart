import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import 'package:collection/collection.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  LocationScreenState createState() => LocationScreenState();
}

class LocationScreenState extends State<LocationScreen> {
  final TextEditingController _nameController = TextEditingController();
  LatLng? _pickedLocation;

  final _formKey = GlobalKey<FormState>();

  GoogleMapController? mapController;

  void _selectLocation(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locations =
        Provider.of<LocationProvider>(context, listen: false).locations;
    final markerSet = locations.mapIndexed(
      (index, marker) {
        return Marker(
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    "Please select the point you want to choose as the attendance point."),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  "Legends:",
                  textAlign: TextAlign.left,
                ),
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.green,
                      ),
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    const Text(": Points that already been set"),
                  ],
                ),
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
                    const Text(": Your current position"),
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
                    const Text(": Area within a 50m radius of your position"),
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
                    const Text(": Your selected position."),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                FutureBuilder(
                  future: getCurrentLocation(),
                  builder: (context, snapshot) {
                    Set<Circle> circles = {
                      Circle(
                        circleId: const CircleId("currentLoc"),
                        center: LatLng(snapshot.data?.latitude ?? 0,
                            snapshot.data?.longitude ?? 0),
                        radius: 50,
                        strokeWidth: 4,
                        strokeColor: Colors.lightBlue.withOpacity(0.75),
                      ),
                    };
                    final Marker currentLocMarker = Marker(
                      markerId: const MarkerId('user_location'),
                      position: snapshot.data ?? const LatLng(0.0, 0.0),
                      infoWindow: const InfoWindow(title: 'Your Location'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                    );
                    Set<Marker> markers = {
                      currentLocMarker,
                      ...markerSet,
                      ...((_pickedLocation == null
                          ? {}
                          : {
                              Marker(
                                onDragStart: (value) {
                                  mapController?.showMarkerInfoWindow(
                                    const MarkerId('m1'),
                                  );
                                },
                                infoWindow: InfoWindow(
                                  title:
                                      "(${_pickedLocation?.latitude ?? 0}, ${_pickedLocation?.longitude ?? 0})",
                                ),
                                onDragEnd: (value) {
                                  _selectLocation(value);
                                },
                                draggable: true,
                                markerId: const MarkerId('m1'),
                                position:
                                    _pickedLocation ?? const LatLng(0.0, 0.0),
                              )
                            })),
                    };
                    return SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: snapshot.hasError
                          ? const Center(child: Text("Google Map Error."))
                          : !snapshot.hasData
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(
                                        height: 8,
                                      ),
                                      Text("Getting current location..."),
                                    ],
                                  ),
                                )
                              : GoogleMap(
                                  onMapCreated: (mapController) {
                                    this.mapController = mapController;
                                  },
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                        snapshot.data?.latitude as double,
                                        snapshot.data?.longitude as double),
                                    zoom: 16,
                                  ),
                                  onTap: _selectLocation,
                                  markers: markers,
                                  circles: circles,
                                ),
                    );
                  },
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Location Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location name';
                    }

                    if (!Provider.of<LocationProvider>(context, listen: false)
                        .checkIfUnique(value)) {
                      return 'Location name already exists';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                ElevatedButton(
                  child: const Text('Save Location'),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    if (_pickedLocation == null) {
                      Fluttertoast.showToast(
                          msg: "Please choose location on the map.");
                    }
                    Provider.of<LocationProvider>(context, listen: false)
                        .addLocation(
                      _nameController.text,
                      _pickedLocation!.latitude,
                      _pickedLocation!.longitude,
                    );
                    Navigator.of(context).pop();
                    Fluttertoast.showToast(
                      msg:
                          "Added \"${_nameController.text}\" at (${_pickedLocation!.latitude}, ${_pickedLocation!.longitude}) on the location list.",
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<LatLng> getCurrentLocation() async {
    final location = await Provider.of<LocationProvider>(context, listen: false)
        .getCurrentLocation();
    return LatLng(location.latitude, location.longitude);
  }
}
