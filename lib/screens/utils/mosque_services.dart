import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'mosque_model.dart';

class MosqueService {
  Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<List<Mosque>> fetchNearbyMosques() async {
    Position position = await getUserLocation();

    double lat = position.latitude;
    double lon = position.longitude;

    /// 2km radius mosque search
    String url =
        "https://overpass-api.de/api/interpreter?data=[out:json];node(around:2000,$lat,$lon)[amenity=place_of_worship][religion=muslim];out;";

    final response = await http.get(Uri.parse(url));

    final data = json.decode(response.body);

    List<Mosque> mosques = [];

    for (var element in data["elements"]) {
      double mLat = element["lat"];
      double mLon = element["lon"];

      double distance = Geolocator.distanceBetween(lat, lon, mLat, mLon) / 1000;

      mosques.add(
        Mosque(
          name: element["tags"]?["name"] ?? "Nearby Mosque",
          lat: mLat,
          lon: mLon,
          distance: distance,
        ),
      );
    }

    mosques.sort((a, b) => a.distance.compareTo(b.distance));

    return mosques;
  }
}
