import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'login_page.dart';
import 'kml_parser.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({Key? key}) : super(key: key);

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  GoogleMapController? mapController;
  List<LatLng> polylinePoints = [];
  List<Map<String, dynamic>> stops = [];
  String etaMessage = '';

  // Currently selected route.
  String _selectedRoute = 'Clockwise (M1)';
  final List<String> _routes = [
    'Clockwise (M1)',
    'Counter-Clockwise (M2)',
    'The Current'
  ];

  // Selected start and end stops for ETA calculation.
  String? _selectedStartStop;
  String? _selectedEndStop;

  // Firebase Database reference for the shuttle's live location.
  late DatabaseReference _busLocationRef;
  StreamSubscription<DatabaseEvent>? _busLocationSubscription;

  // Marker icons.
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _startStopIcon;
  BitmapDescriptor? _endStopIcon;

  // Bus's live location (as updated in Firebase).
  LatLng _busLocation = const LatLng(34.056004, -117.819326);

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers(); // Unchanged.
    _loadRouteData(); // Load the designated route (polyline and stops) from KML.
    _subscribeBusLocation(); // Subscribe to Firebase for the live bus location.
  }

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
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRouteData() async {
    String assetPath = (_selectedRoute == 'The Current')
        ? 'assets/TheCurrent.kml'
        : 'assets/TheShuttle.kml';
    try {
      final Map<String, dynamic> data = await parseKML(assetPath);
      if (mounted) {
        setState(() {
          polylinePoints = data['polyline'] ?? [];
          stops = data['stops'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading route data: $e');
      if (mounted) {
        setState(() {
          etaMessage = 'Error loading route data.';
        });
      }
    }
  }

  void _subscribeBusLocation() {
    _busLocationRef =
        FirebaseDatabase.instance.ref('shuttleLocation/$_selectedRoute');
    _busLocationSubscription =
        _busLocationRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final lat = data['latitude'];
        final lon = data['longitude'];
        if (lat != null && lon != null) {
          if (mounted) {
            setState(() {
              _busLocation = LatLng(
                (lat is num ? lat.toDouble() : 0.0),
                (lon is num ? lon.toDouble() : 0.0),
              );
            });
          }
        }
      }
    }, onError: (error) {
      debugPrint('Error reading bus location: $error');
    });
  }

  void _unsubscribeBusLocation() {
    _busLocationSubscription?.cancel();
  }

  @override
  void dispose() {
    _unsubscribeBusLocation();
    super.dispose();
  }

  Set<Marker> _createMarkers() {
    Set<Marker> markers = {};

    // Bus marker from Firebase live data.
    markers.add(
      Marker(
        markerId: const MarkerId('bus'),
        position: _busLocation,
        icon: _busIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: "Shuttle"),
      ),
    );

    // Stop markers from the route.
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      if (!stop.containsKey('name') || !stop.containsKey('latlng')) continue;
      final LatLng position = stop['latlng'];
      final String stopName = stop['name'];
      markers.add(
        Marker(
          markerId: MarkerId('stop_${i}_$stopName'),
          position: position,
          icon: (_selectedStartStop == stopName)
              ? (_startStopIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen))
              : (_selectedEndStop == stopName)
                  ? (_endStopIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed))
                  : (_stopIcon ?? BitmapDescriptor.defaultMarker),
          infoWindow: InfoWindow(title: stopName),
          onTap: () async {
            await mapController
                ?.animateCamera(CameraUpdate.newLatLng(position));
            mapController
                ?.showMarkerInfoWindow(MarkerId('stop_${i}_$stopName'));
          },
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _createPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('route_polyline'),
        points: polylinePoints,
        color: Colors.blue,
        width: 3,
      ),
    };
  }

  void _onRouteChanged(String? newRoute) {
    if (newRoute != null && newRoute != _selectedRoute) {
      _unsubscribeBusLocation();
      if (mounted) {
        setState(() {
          _selectedRoute = newRoute;
          _selectedStartStop = null;
          _selectedEndStop = null;
        });
      }
      _loadRouteData();
      _subscribeBusLocation();
    }
  }

  Future<void> _selectStop(bool isStart) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: stops.length,
          itemBuilder: (context, index) {
            final stop = stops[index];
            if (!stop.containsKey('name')) return const SizedBox.shrink();
            final String stopName = stop['name'];
            return ListTile(
              title: Text(stopName),
              onTap: () {
                if (mounted) {
                  setState(() {
                    if (isStart) {
                      _selectedStartStop = stopName;
                    } else {
                      _selectedEndStop = stopName;
                    }
                  });
                }
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _calculateETA() {
    if (_selectedStartStop == null || _selectedEndStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end stops')),
      );
      return;
    }
    if (mounted) {
      setState(() {
        etaMessage =
            'ETA from $_selectedStartStop to $_selectedEndStop: 8 minutes.';
      });
    }
    Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() {
        etaMessage = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialTarget;
    if (polylinePoints.isNotEmpty) {
      initialTarget = polylinePoints.first;
    } else {
      initialTarget = _busLocation;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Shuttle Status ($_selectedRoute)'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          ),
        ),
      ),
      body: (polylinePoints.isEmpty && stops.isEmpty)
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
                  markers: Set<Marker>.of(_createMarkers()),
                  polylines: _createPolylines(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                // Route selection dropdown at top left.
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4.0)
                      ],
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRoute,
                      underline: Container(),
                      items: _routes
                          .map((route) => DropdownMenuItem<String>(
                                value: route,
                                child: Text(route,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: _onRouteChanged,
                    ),
                  ),
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
                // Draggable bottom sheet for selecting stops and calculating ETA.
                DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.1,
                  maxChildSize: 0.5,
                  builder: (BuildContext context,
                      ScrollController scrollController) {
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8.0),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          const Text(
                            'Select Stops',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          ListTile(
                            title:
                                Text(_selectedStartStop ?? 'Select Start Stop'),
                            trailing: const Icon(Icons.arrow_drop_down),
                            onTap: () => _selectStop(true),
                          ),
                          const SizedBox(height: 8.0),
                          ListTile(
                            title: Text(_selectedEndStop ?? 'Select End Stop'),
                            trailing: const Icon(Icons.arrow_drop_down),
                            onTap: () => _selectStop(false),
                          ),
                          const SizedBox(height: 12.0),
                          Center(
                            child: ElevatedButton(
                              onPressed: _calculateETA,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 64.0, vertical: 12.0),
                              ),
                              child: const Text(
                                'Get ETA',
                                style: TextStyle(
                                    fontSize: 16.0, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Display ETA message.
                if (etaMessage.isNotEmpty)
                  Positioned(
                    top: 80.0,
                    left: 16.0,
                    right: 16.0,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        etaMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
