// lib/kml_parser.dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:xml/xml.dart';

Future<Map<String, dynamic>> parseKML(String assetPath) async {
  final String kmlString = await rootBundle.loadString(assetPath);
  final XmlDocument document = XmlDocument.parse(kmlString);

  // ---------------------------
  // Extract polyline points from ALL <LineString> elements.
  // ---------------------------
  List<LatLng> polylinePoints = [];
  final List<XmlElement> lineStringElements =
      document.findAllElements('LineString').toList();
  for (final ls in lineStringElements) {
    final List<XmlElement> coordsElements =
        ls.findElements('coordinates').toList();
    for (final coordsElement in coordsElements) {
      final String coordsString = coordsElement.text.trim();
      final List<String> coordList = coordsString.split(RegExp(r'\s+'));
      for (final coord in coordList) {
        if (coord.isEmpty) continue;
        final List<String> parts = coord.split(',');
        if (parts.length >= 2) {
          double lon = double.tryParse(parts[0]) ?? 0.0;
          double lat = double.tryParse(parts[1]) ?? 0.0;
          polylinePoints.add(LatLng(lat, lon));
        }
      }
    }
  }

  // ---------------------------
  // Extract stops from <Placemark> elements that contain a <Point>.
  // ---------------------------
  List<Map<String, dynamic>> stops = [];
  final List<XmlElement> placemarks =
      document.findAllElements('Placemark').toList();
  for (final placemark in placemarks) {
    final List<XmlElement> pointElements =
        placemark.findElements('Point').toList();
    if (pointElements.isEmpty) continue;
    final XmlElement pointElement = pointElements.first;
    final List<XmlElement> nameElements =
        placemark.findElements('name').toList();
    final String stopName = nameElements.isNotEmpty
        ? nameElements.first.text.trim()
        : 'Unnamed Stop';
    final List<XmlElement> coordsElements =
        pointElement.findElements('coordinates').toList();
    if (coordsElements.isEmpty) continue;
    final String pointCoords = coordsElements.first.text.trim();
    final List<String> parts = pointCoords.split(',');
    if (parts.length >= 2) {
      double lon = double.tryParse(parts[0]) ?? 0.0;
      double lat = double.tryParse(parts[1]) ?? 0.0;
      stops.add({'name': stopName, 'latlng': LatLng(lat, lon)});
    }
  }

  return {
    'polyline': polylinePoints,
    'stops': stops,
  };
}
