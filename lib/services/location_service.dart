import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UserLocationResult {
  final double latitude;
  final double longitude;
  final String houseNo;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String fullFormattedAddress;

  UserLocationResult({
    required this.latitude,
    required this.longitude,
    required this.houseNo,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.fullFormattedAddress,
  });
}

class LocationService {
  static Future<UserLocationResult?> fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String houseNo = place.name ?? place.subThoroughfare ?? '';
        String area = [place.subLocality, place.thoroughfare]
            .where((element) => element != null && element.isNotEmpty)
            .join(', ');
        if (area.isEmpty) area = place.locality ?? '';
        String city = place.locality ?? place.subAdministrativeArea ?? 'Bengaluru';
        String state = place.administrativeArea ?? 'Karnataka';
        String pincode = place.postalCode ?? '560001';

        String fullFormatted = [
          if (houseNo.isNotEmpty) houseNo,
          if (area.isNotEmpty) area,
          if (city.isNotEmpty) city,
          if (state.isNotEmpty) state,
          if (pincode.isNotEmpty) pincode,
        ].join(', ');

        return UserLocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          houseNo: houseNo,
          area: area,
          city: city,
          state: state,
          pincode: pincode,
          fullFormattedAddress: fullFormatted.isNotEmpty
              ? fullFormatted
              : 'Koramangala 5th Block, Bengaluru, Karnataka, 560095',
        );
      }
    } catch (e) {
      debugPrint('LocationService fetch error: $e');
    }
    return null;
  }
}
