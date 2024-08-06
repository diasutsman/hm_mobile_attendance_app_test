import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _locations = [];

  List<Map<String, dynamic>> get locations => _locations;

  Map<String, dynamic> locationNames = {};

  void addLocation(String name, double latitude, double longitude) {
    assert(checkIfUnique(name));
    _locations.add({
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    });
    locationNames[name] = true;
    notifyListeners();
  }

  bool checkIfUnique(String name) {
    return !locationNames.containsKey(name);
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  bool isWithinDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude, double distanceInMeters) {
    double distance = getDistanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
    return distance <= distanceInMeters;
  }

  double getDistanceBetween(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
  }

  LatLng getMiddlePointOfPoints(List<LatLng> points) {
    var latt = 0.0, lon = 0.0;
    for (var point in points) {
      latt += point.latitude;
      lon += point.longitude;
    }
    latt /= points.length;
    lon /= points.length;
    return LatLng(latt, lon);
  }
}
