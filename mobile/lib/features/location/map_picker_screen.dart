import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../crops/data/location.dart'; // your LocationData model

class MapPickerScreen extends StatefulWidget {
  final LatLng? start;
  const MapPickerScreen({super.key, this.start});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _picked;
  // ignore: unused_field
  GoogleMapController? _ctrl;

  @override
  Widget build(BuildContext context) {
    final start = widget.start ?? const LatLng(15.603, 32.532); // Khartoum-ish
    final markers = <Marker>{
      if (_picked != null)
        Marker(markerId: const MarkerId('picked'), position: _picked!),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('اختر الموقع على الخريطة')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: start, zoom: 12),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        onMapCreated: (c) => _ctrl = c,
        onTap: (latLng) => setState(() => _picked = latLng),
        markers: markers,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _picked == null
            ? null
            : () {
                final loc = LocationData(
                  lat: _picked!.latitude,
                  lng: _picked!.longitude,
                  // Optional: fill state/locality/address after reverse geocoding later
                );
                Navigator.of(context).pop(loc);
              },
        label: const Text('تأكيد الموقع'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
