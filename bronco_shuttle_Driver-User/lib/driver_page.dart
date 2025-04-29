import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'DriverRouteSelectionPage.dart';
import 'kml_parser.dart';

class DriverPage extends StatefulWidget {
  final String selectedRoute;
  const DriverPage({Key? key, required this.selectedRoute}) : super(key: key);

  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  StreamSubscription<Position>? _positionStreamSubscription;
  late DatabaseReference _shuttleRef;
  GoogleMapController? mapController;
  Position? _currentPosition;

  // Data from the KML for the designated route.
  List<LatLng> routePolyline = [];
  List<Map<String, dynamic>> routeStops = [];

  // Marker icons.
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _startStopIcon;
  BitmapDescriptor? _endStopIcon;

  // Driver's live location – this will be updated from the Geolocator.
  LatLng _driverLocation = const LatLng(34.056004, -117.819326);

  @override
  void initState() {
    super.initState();
    _shuttleRef = FirebaseDatabase.instance
        .ref('shuttleLocation/${widget.selectedRoute}');
    _loadCustomMarkers(); // Use your unchanged function.
    _loadRouteData(); // Load the designated route map.
    _requestLocationPermission();
  }

  // This function remains unchanged as per your requirement.
  void _loadCustomMarkers() async {
    _stopIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/stops.png',
    );
    _busIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/bus.png',
    );
    _startStopIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/start_stop.png',
    );
    _endStopIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/end_stop.png',
    );
    setState(() {});
  }

  Future<void> _loadRouteData() async {
    // Choose the correct KML file based on the selected route.
    String assetPath = (widget.selectedRoute == 'The Current')
        ? 'assets/TheCurrent.kml'
        : 'assets/TheShuttle.kml';
    try {
      final Map<String, dynamic> data = await parseKML(assetPath);
      setState(() {
        routePolyline = data['polyline'] ?? [];
        routeStops = data['stops'] ?? [];
      });
    } catch (e) {
      debugPrint('Error loading route data: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return;
    }
    debugPrint('Location permissions granted');
    _startTracking();
  }

  void _startTracking() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) {
      // Update Firebase with the current location.
      _shuttleRef.set({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
      setState(() {
        _currentPosition = position;
        _driverLocation = LatLng(position.latitude, position.longitude);
      });
      // Animate camera to follow the driver's live location.
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    }, onError: (error) {
      debugPrint('Error receiving location updates: $error');
    });
  }

  void _goBack() {
    _positionStreamSubscription?.cancel();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DriverRouteSelectionPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Set<Marker> _createMarkers() {
    Set<Marker> markers = {};

    // Driver marker uses the bus icon.
    if (_busIcon != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: _driverLocation,
          icon: _busIcon!,
          infoWindow: const InfoWindow(title: "You Are Here"),
        ),
      );
    } else {
      // Fallback if _busIcon is not yet loaded.
      markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: _driverLocation,
          infoWindow: const InfoWindow(title: "You Are Here"),
        ),
      );
    }

    // Add route stops (if needed) so driver can see them on the map.
    for (int i = 0; i < routeStops.length; i++) {
      final stop = routeStops[i];
      if (!stop.containsKey('name') || !stop.containsKey('latlng')) continue;
      final LatLng position = stop['latlng'];
      final String name = stop['name'];
      markers.add(
        Marker(
          markerId: MarkerId('stop_${i}_$name'),
          position: position,
          icon: _stopIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: name),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _createPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('route_polyline'),
        points: routePolyline,
        color: Colors.blue,
        width: 3,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Determine an initial camera target.
    LatLng initialTarget;
    if (routePolyline.isNotEmpty) {
      initialTarget = routePolyline.first;
    } else if (_currentPosition != null) {
      initialTarget =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    } else {
      initialTarget = const LatLng(34.056004, -117.819326);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Page (${widget.selectedRoute})'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: (_currentPosition == null && routePolyline.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: initialTarget,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  padding: const EdgeInsets.only(bottom: 60, right: 16),
                  markers: _createMarkers(),
                  polylines: _createPolylines(),
                ),
                // Zoom controls at top right.
                Positioned(
                  top: 16.0,
                  right: 16.0,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoomIn',
                        backgroundColor: Colors.green,
                        onPressed: () =>
                            mapController?.animateCamera(CameraUpdate.zoomIn()),
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8.0),
                      FloatingActionButton.small(
                        heroTag: 'zoomOut',
                        backgroundColor: Colors.green,
                        onPressed: () => mapController
                            ?.animateCamera(CameraUpdate.zoomOut()),
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
