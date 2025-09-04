// Clean English version using brand buttons
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../widgets/brand_button.dart';
import '../../crops/state/providers.dart';
import '../data/location.dart';

class AddCropScreen extends ConsumerStatefulWidget {
  const AddCropScreen({super.key});

  @override
  ConsumerState<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends ConsumerState<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  String _selectedType = 'Vegetables';
  String _selectedUnit = 'kg';
  final List<XFile> _selectedImages = [];
  LocationData? _selectedLocation;

  final List<String> _cropTypes = const [
    'Vegetables', 'Fruits', 'Grains', 'Legumes', 'Herbs', 'Other'
  ];
  final List<String> _units = const ['kg', 'ton', 'bag', 'box', 'unit'];

  final _picker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (files == null) return;
      setState(() {
        _selectedImages.addAll(files.take(5 - _selectedImages.length));
      });
    } catch (_) {
      _toast('Failed to pick images');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final f = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (f == null) return;
      setState(() {
        if (_selectedImages.length < 5) _selectedImages.add(f);
      });
    } catch (_) {
      _toast('Failed to open camera');
    }
  }

  Future<void> _selectLocation() async {
    final loc = await context.push<LocationData>('/map-picker');
    if (!mounted) return;
    if (loc != null) setState(() => _selectedLocation = loc);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Crop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Basic info', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Crop name*', prefixIcon: Icon(Icons.spa_outlined), isDense: true),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: _cropTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _selectedType = v ?? _selectedType),
                    decoration: const InputDecoration(labelText: 'Type*', prefixIcon: Icon(Icons.category_outlined), isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity*', prefixIcon: Icon(Icons.scale), isDense: true),
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v ?? _selectedUnit),
                    decoration: const InputDecoration(labelText: 'Unit*', isDense: true),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price*', prefixIcon: Icon(Icons.attach_money), isDense: true),
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes_outlined)),
                maxLines: 3,
              ),

              const SizedBox(height: 20),
              Text('Photos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: PrimaryButton(
                    onPressed: _selectedImages.length < 5 ? _pickImages : null,
                    icon: Icons.photo_library,
                    label: 'Pick images',
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    onPressed: _selectedImages.length < 5 ? _takePhoto : null,
                    icon: Icons.camera_alt,
                    label: 'Take photo',
                    expanded: true,
                  ),
                ),
              ]),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Selected (${_selectedImages.length}/5)', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      final f = _selectedImages[i];
                      return Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(f.path), width: 120, height: 86, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => setState(() => _selectedImages.removeAt(i)),
                            child: Container(
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        )
                      ]);
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: _selectedImages.length,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Text('Location', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: _selectLocation,
                  icon: _selectedLocation == null ? Icons.location_on : Icons.edit_location,
                  label: _selectedLocation == null ? 'Select location' : 'Edit location',
                  expanded: true,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedLocation != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primaryContainer),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_selectedLocation!.address ?? 'No address', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Lat: ${_selectedLocation!.lat.toStringAsFixed(6)}  •  Lng: ${_selectedLocation!.lng.toStringAsFixed(6)}'),
                  ]),
                ),

              const SizedBox(height: 24),
              PrimaryButton(label: 'Publish', onPressed: _submit, expanded: true),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _toast('Please fill in the required fields');
      return;
    }
    if (_selectedLocation == null) {
      _toast('Please select a location');
      return;
    }

    final name = _nameController.text.trim();
    final type = _selectedType;
    final qty = double.tryParse(_quantityController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    final unit = _selectedUnit;
    final notes = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();
    if (qty == null || price == null) {
      _toast('Invalid quantity or price');
      return;
    }

    try {
      final repo = ref.read(cropsRepoProvider);
      final files = _selectedImages.map((x) => File(x.path)).toList();
      final created = await repo.create(
        name: name,
        type: type,
        qty: qty,
        price: price,
        unit: unit,
        location: _selectedLocation!,
        notes: notes,
        images: files,
      );
      if (!mounted) return;
      _toast('Listing published');
      context.go('/crops/${created.id}');
    } catch (e) {
      if (!mounted) return;
      _toast('Failed to publish: $e');
    }
  }
}
