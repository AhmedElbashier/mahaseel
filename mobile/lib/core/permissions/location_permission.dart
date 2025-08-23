import 'package:geolocator/geolocator.dart';

class LocationPerms {
  static Future<bool> ensure() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }
}
