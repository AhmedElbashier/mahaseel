// lib/features/location/map_picker_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../crops/data/location.dart' show LocationData; // same model you're using

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // Khartoum as a sensible default
  static const LatLng _khartoum = LatLng(15.5007, 32.5599);
  static const CameraPosition _initialCamera =
  CameraPosition(target: _khartoum, zoom: 12);

  LatLng? _picked;
  bool _locating = false;

  // Simple text fields for address meta (reverse geocode optional later)
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
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final LatLng here = LatLng(pos.latitude, pos.longitude);
      _picked = here;

      final c = await _controller.future;
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: here, zoom: 15),
        ),
      );
    } catch (_) {
      // If permission denied or location off, keep silent and stay at default
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحديد موقعك الحالي'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    if (_picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر موقعاً على الخريطة أولاً'),
          backgroundColor: Colors.red,
        ),
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Gradient header like your add screen
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
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
                        'اختر الموقع على الخريطة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // Map + form
          SliverFillRemaining(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: 16 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Map card
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _card(
                            context: context,
                            child: SizedBox(
                              height: 280,
                              child: Stack(
                                children: [
                                  GoogleMap(
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    mapType: MapType.normal,
                                    initialCameraPosition: _initialCamera,
                                    onMapCreated: (ctrl) => _controller.complete(ctrl),
                                    onTap: (latLng) => setState(() => _picked = latLng),
                                    markers: {
                                      if (_picked != null)
                                        Marker(
                                          markerId: const MarkerId('picked'),
                                          position: _picked!,
                                        ),
                                    },
                                  ),
                                  PositionedDirectional(
                                    bottom: 12,
                                    start: 12,
                                    child: ElevatedButton.icon(
                                      onPressed: _locating ? null : _goToMyLocation,
                                      icon: _locating
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                          : const Icon(Icons.my_location),
                                      label: const Text('موقعي'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Picked summary + manual address fields
                        if (_picked != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _card(
                              context: context,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.pin_drop, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      const Text('الموقع المحدد', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'خط العرض: ${_picked!.latitude.toStringAsFixed(6)}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'خط الطول: ${_picked!.longitude.toStringAsFixed(6)}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _addressCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'العنوان (اختياري)',
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
                                            labelText: 'الولاية (اختياري)',
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
                                            labelText: 'المحلية/المدينة (اختياري)',
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
                          ),

                        // Push buttons to bottom if there’s extra space; otherwise they’ll be just below the content.
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.pop(),
                                    icon: const Icon(Icons.close),
                                    label: const Text('إلغاء'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _confirm,
                                    icon: const Icon(Icons.check),
                                    label: const Text('تأكيد الموقع'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
