// lib/features/crops/screens/add_crop_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../crops/data/location.dart'; // ⬅️ moved from data/ to models/
import '../../crops/providers.dart';

class AddCropScreen extends ConsumerStatefulWidget {
  const AddCropScreen({super.key});

  @override
  ConsumerState<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends ConsumerState<AddCropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _type = TextEditingController();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  final _notes = TextEditingController();

  LocationData? _loc; // Day 16: replace with real map picker
  final _images = <File>[];
  final _picker = ImagePicker();
  bool _submitting = false;

  static const _draftKey = 'draft:add_crop_v1';

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _qty.dispose();
    _price.dispose();
    _unit.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_draftKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _name.text = j['name'] ?? '';
      _type.text = j['type'] ?? '';
      _qty.text = (j['qty'] ?? '').toString();
      _price.text = (j['price'] ?? '').toString();
      _unit.text = j['unit'] ?? 'kg';
      _notes.text = j['notes'] ?? '';
      final loc = j['location'] as Map<String, dynamic>?;
      if (loc != null) _loc = LocationData.fromJson(loc);
      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    final sp = await SharedPreferences.getInstance();
    final j = {
      'name': _name.text,
      'type': _type.text,
      'qty': _qty.text,
      'price': _price.text,
      'unit': _unit.text,
      'notes': _notes.text,
      'location': _loc?.toJson(),
    };
    await sp.setString(_draftKey, jsonEncode(j));
  }

  Future<void> _pickImage(ImageSource src) async {
    final x = await _picker.pickImage(
      source: src,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (x != null) {
      setState(() => _images.add(File(x.path)));
      _saveDraft();
    }
  }

  void _fakePickLocation() {
    // Day 14 placeholder; Day 16 will use maps & permissions
    _loc = LocationData(
      lat: 15.603,
      lng: 32.532,
      state: 'Khartoum',
      locality: 'Bahri',
      address: 'Market St.',
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم تعيين الموقع التجريبي')));
    _saveDraft();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الموقع')),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      final repo = ref.read(cropsRepoProvider);
      final crop = await repo.createJson(
        name: _name.text.trim(),
        type: _type.text.trim(),
        qty: double.parse(_qty.text),
        price: double.parse(_price.text),
        unit: _unit.text.trim(),
        location: _loc!,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      ;

      final sp = await SharedPreferences.getInstance();
      await sp.remove(_draftKey);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر المحصول بنجاح')),
      );
      // ⬇️ Use GoRouter, consistent with your router setup
      context.go('/crops/${crop.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الإرسال: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final numKeyboard = const TextInputType.numberWithOptions(decimal: true);
    final numFormatters = <TextInputFormatter>[
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة محصول')),
      body: Form(
        key: _formKey,
        onChanged: _saveDraft,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _images)
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          f,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _images.remove(f));
                          _saveDraft();
                        },
                        tooltip: 'إزالة الصورة',
                      ),
                    ],
                  ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('المعرض'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('الكاميرا'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم المحصول'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            TextFormField(
              controller: _type,
              decoration: const InputDecoration(labelText: 'النوع'),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qty,
                    decoration: const InputDecoration(labelText: 'الكمية'),
                    keyboardType: numKeyboard,
                    inputFormatters: numFormatters,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final x = double.tryParse(v);
                      if (x == null || x <= 0) return 'قيمة غير صحيحة';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(
                        labelText: 'الوحدة (مثال: kg، طن)'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'السعر'),
                    keyboardType: numKeyboard,
                    inputFormatters: numFormatters,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'مطلوب';
                      final x = double.tryParse(v);
                      if (x == null || x <= 0) return 'قيمة غير صحيحة';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration:
              const InputDecoration(labelText: 'ملاحظات (اختياري)'),
            ),
            const SizedBox(height: 12),

            ListTile(
              title: Text(
                _loc == null
                    ? 'لم يتم تعيين الموقع بعد'
                    : 'الموقع: ${_loc!.state ?? ''} • ${_loc!.locality ?? ''}',
              ),
              subtitle: Text(
                _loc?.address ?? 'lat=${_loc?.lat}, lng=${_loc?.lng}',
              ),
              trailing: OutlinedButton.icon(
                onPressed: _fakePickLocation,
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('اختيار الموقع'),
              ),
            ),
            const SizedBox(height: 20),

            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('نشر المحصول'),
            ),
          ],
        ),
      ),
    );
  }
}
