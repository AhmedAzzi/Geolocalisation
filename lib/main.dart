// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:flutter/foundation.dart' show Key, debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> _data = [];
  LocationData? _locationData;
  final Location _location = Location();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      final permissionStatus = await _location.hasPermission();
      if (permissionStatus == PermissionStatus.denied) {
        if (await _location.requestPermission() != PermissionStatus.granted) {
          return;
        }
      }

      final currentLocation = await _location.getLocation();
      setState(() {
        _locationData = currentLocation;
        _mapController.move(
            LatLng(currentLocation.latitude!, currentLocation.longitude!),
            15.0);
      });
    } catch (e) {
      debugPrint('Could not get the location: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/locations.json');
      final jsonData = jsonDecode(jsonString) as List<dynamic>;
      setState(() => _data = jsonData.cast<Map<String, dynamic>>());
    } catch (e) {
      if (kDebugMode) print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Geolocalisation',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Geolocalisation'),
          actions: [
            _buildIconButton(
              onPressed: () => _mapController.move(
                  _mapController.center, _mapController.zoom + 1),
              icon: const Icon(Icons.zoom_in, color: Colors.white),
              tooltip: 'Zoom In',
            ),
            const Padding(padding: EdgeInsets.only(right: 16)),
            _buildIconButton(
              onPressed: () => _mapController.move(
                  _mapController.center, _mapController.zoom - 1),
              icon: const Icon(Icons.zoom_out, color: Colors.white),
              tooltip: 'Zoom Out',
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _locationData != null
                      ? LatLng(
                          _locationData!.latitude!, _locationData!.longitude!)
                      : LatLng(51.5, -0.09),
                  zoom: 10.0,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  if (_locationData != null)
                    MarkerLayerOptions(
                      markers: [
                        Marker(
                          point: LatLng(_locationData!.latitude!,
                              _locationData!.longitude!),
                          builder: (_) => const Icon(Icons.accessibility_sharp,
                              color: Colors.blue, size: 42.0),
                        ),
                      ],
                    ),
                  MarkerLayerOptions(
                    markers: _data
                        .map(
                          (location) => Marker(
                            point: LatLng(
                              _parseDouble(location['lat']),
                              _parseDouble(location['lon']),
                            ),
                            builder: (context) => IconButton(
                              icon: const Icon(
                                Icons.medication_rounded,
                                color: Color.fromARGB(255, 168, 13, 2),
                                size: 32.0,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      location['name'] +
                                          '\n' +
                                          'Address: ' +
                                          location['address'],
                                    ),
                                    action: SnackBarAction(
                                      label: 'Close',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                      },
                                    ),
                                  ),
                                );

                                Future.delayed(const Duration(seconds: 3), () {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onPressed,
    required Icon icon,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: icon,
      color: Colors.blue,
      splashColor: Colors.white,
      highlightColor: Colors.white,
      tooltip: tooltip,
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null || value == '') {
      return 0.0;
    }
    if (value is double) {
      return value;
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
