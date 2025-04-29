// distance_matrix_service.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DistanceMatrixService {
  final String apiKey;
  DistanceMatrixService({required this.apiKey});

  /// Fetches travel time (in seconds) between origin and destination.
  Future<int> getTravelTimeInSeconds(LatLng origin, LatLng destination) async {
    final url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'units=metric'
        '&origins=${origin.latitude},${origin.longitude}'
        '&destinations=${destination.latitude},${destination.longitude}'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'OK') {
        final element = jsonResponse['rows'][0]['elements'][0];
        if (element['status'] == 'OK') {
          final int durationInSeconds = element['duration']['value'];
          return durationInSeconds;
        } else {
          throw Exception('Element status error: ${element['status']}');
        }
      } else {
        throw Exception('Distance Matrix API error: ${jsonResponse['status']}');
      }
    } else {
      throw Exception('Failed to call API: ${response.statusCode}');
    }
  }
}
