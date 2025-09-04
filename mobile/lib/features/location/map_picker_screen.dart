// lib/features/location/map_picker_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../crops/data/location.dart' show LocationData;
import '../../widgets/brand_button.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng _khartoum = LatLng(15.5007, 32.5599);
  static const CameraPosition _initialCamera = CameraPosition(target: _khartoum, zoom: 12);

  LatLng? _picked;
  bool _locating = false;

  final _addressCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    _stateCtrl.dispose();
    _localityCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        throw Exception('location_denied');
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final here = LatLng(pos.latitude, pos.longitude);
      _picked = here;
      final c = await _controller.future;
      await c.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: here, zoom: 15)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location unavailable. Please enable permissions.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    if (_picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on the map.')),
      );
      return;
    }
    final loc = LocationData(
      lat: _picked!.latitude,
      lng: _picked!.longitude,
      state: _stateCtrl.text.isEmpty ? null : _stateCtrl.text,
      locality: _localityCtrl.text.isEmpty ? null : _localityCtrl.text,
      address: _addressCtrl.text.isEmpty ? null : _addressCtrl.text,
    );
    context.pop<LocationData>(loc);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.secondary],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      SizedBox(height: 20),
                      Icon(Icons.location_on, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'Pick location for your listing',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 320,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: _initialCamera,
                            onMapCreated: (ctrl) => _controller.complete(ctrl),
                            zoomControlsEnabled: false,
                            onTap: (latLng) => setState(() => _picked = latLng),
                            markers: {
                              if (_picked != null)
                                Marker(markerId: const MarkerId('picked'), position: _picked!),
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                          ),
                          PositionedDirectional(
                            bottom: 12,
                            start: 12,
                            child: PrimaryButton(
                              onPressed: _locating ? null : _goToMyLocation,
                              icon: Icons.my_location,
                              label: _locating ? 'Locating…' : 'My location',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  _card(
                    context: context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pin_drop, color: cs.primary),
                            const SizedBox(width: 8),
                            const Text('Selected location', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_picked != null) ...[
                          Row(children: [
                            Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('Lat: ${_picked!.latitude.toStringAsFixed(6)}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('Lng: ${_picked!.longitude.toStringAsFixed(6)}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ]),
                        ] else
                          const Text('Tap the map to select a location', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  _card(
                    context: context,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Address (optional)',
                            prefixIcon: Icon(Icons.home_outlined),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stateCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'State (optional)',
                                  prefixIcon: Icon(Icons.map_outlined),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _localityCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Locality/City (optional)',
                                  prefixIcon: Icon(Icons.location_city_outlined),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlineButtonBrand(
                          onPressed: () => context.pop(),
                          icon: Icons.close,
                          label: 'Cancel',
                          expanded: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          onPressed: _confirm,
                          icon: Icons.check,
                          label: 'Use this location',
                          expanded: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required BuildContext context, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

