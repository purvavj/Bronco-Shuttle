import 'package:flutter/material.dart';
import 'driver_page.dart';

class DriverRouteSelectionPage extends StatefulWidget {
  const DriverRouteSelectionPage({Key? key}) : super(key: key);

  @override
  State<DriverRouteSelectionPage> createState() =>
      _DriverRouteSelectionPageState();
}

class _DriverRouteSelectionPageState extends State<DriverRouteSelectionPage> {
  // List of available routes (you can update these as needed)
  final List<String> _routes = [
    'Clockwise (M1)',
    'Counter-Clockwise (M2)',
    'The Current'
  ];
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    // Optionally set a default route.
    _selectedRoute = _routes.first;
  }

  void _continue() {
    if (_selectedRoute != null) {
      // Navigate to the DriverPage, passing the selected route.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverPage(selectedRoute: _selectedRoute!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Route'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedRoute,
                decoration: const InputDecoration(
                  labelText: 'Select Route',
                  border: OutlineInputBorder(),
                ),
                items: _routes
                    .map((route) => DropdownMenuItem(
                          value: route,
                          child: Text(route),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoute = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _continue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
