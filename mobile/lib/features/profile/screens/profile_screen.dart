
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../auth/state/auth_controller.dart';
import '../../settings/state/settings_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _businessNameController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    try {
      final dynamic s = ref.read(authControllerProvider);
      final dynamic u = s?.user; // many auth states expose `user`
      if (u != null) {
        final n = (u.name is String) ? u.name as String : null;
        final p = (u.phone is String) ? u.phone as String : null;
        if (n != null) _nameController.text = n;
        if (p != null) _phoneController.text = p;
      }
    } catch (_) {
      // ignore: state shape is different (e.g., no .user) – that's fine
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _businessNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save),
            tooltip: 'حفظ التغييرات',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Profile Picture Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : 'اسم المستخدم',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'المزارع', // or pull from your own enum/source later
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Basic Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'المعلومات الأساسية',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الكامل',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال الاسم الكامل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: false, // Phone number shouldn't be editable
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'الموقع',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        suffixIcon: Icon(Icons.gps_fixed),
                      ),
                      onTap: _selectLocation,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Business Info Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'معلومات العمل',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المزرعة أو العمل',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.agriculture),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'نبذة مختصرة',
                        hintText: 'اكتب نبذة مختصرة عن عملك ومحاصيلك...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Account Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'إعدادات الحساب',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('إظهار الملف الشخصي للعامة'),
                      subtitle: const Text('السماح للمشترين برؤية ملفك الشخصي'),
                      value: settingsState.publicProfile,
                      onChanged: (value) {
                        ref.read(settingsControllerProvider.notifier)
                            .updatePublicProfile(value);
                      },
                      secondary: const Icon(Icons.visibility),
                    ),
                    SwitchListTile(
                      title: const Text('إظهار رقم الهاتف'),
                      subtitle: const Text('السماح للمشترين برؤية رقم الهاتف'),
                      value: settingsState.showPhone,
                      onChanged: (value) {
                        ref.read(settingsControllerProvider.notifier)
                            .updateShowPhone(value);
                      },
                      secondary: const Icon(Icons.phone_enabled),
                    ),
                    SwitchListTile(
                      title: const Text('السماح بالاتصال المباشر'),
                      subtitle: const Text('السماح للمشترين بالاتصال المباشر'),
                      value: settingsState.allowDirectContact,
                      onChanged: (value) {
                        ref.read(settingsControllerProvider.notifier)
                            .updateAllowDirectContact(value);
                      },
                      secondary: const Icon(Icons.call),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistics Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'إحصائياتي',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'المحاصيل المنشورة',
                            '12',
                            Icons.agriculture,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'الطلبات المكتملة',
                            '8',
                            Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'التقييم',
                            '4.5',
                            Icons.star,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'عدد المتابعين',
                            '25',
                            Icons.people,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ التغييرات'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showDeleteAccountDialog,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text('حذف الحساب', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _selectLocation() {
    // TODO: Implement location picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم إضافة منتقي الموقع قريباً')),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement profile saving logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الملف الشخصي بنجاح')),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف الحساب'),
          content: const Text(
            'هل أنت متأكد من حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه وسيتم حذف جميع بياناتك.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement account deletion logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال طلب حذف الحساب')),
                );
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
