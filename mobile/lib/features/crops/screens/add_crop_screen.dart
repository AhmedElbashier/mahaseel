// lib/features/crops/screens/add_crop_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../state/crops_controller.dart';
import '../data/location.dart';

class AddCropScreen extends ConsumerStatefulWidget {
  const AddCropScreen({super.key});

  @override
  ConsumerState<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends ConsumerState<AddCropScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  String _selectedType = 'خضروات';
  String _selectedUnit = 'كيلوغرام';
  List<XFile> _selectedImages = [];
  LocationData? _selectedLocation;

  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _currentStep = 0;
  final PageController _pageController = PageController();

  final List<String> _cropTypes = [
    'خضروات',
    'فواكه',
    'حبوب',
    'بقوليات',
    'أعشاب',
    'محاصيل نقدية'
  ];

  final List<String> _units = [
    'كيلوغرام',
    'طن',
    'صندوق',
    'كيس',
    'قطعة',
  ];

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'معلومات أساسية',
      'icon': Icons.info_outline,
      'description': 'اسم المحصول ونوعه'
    },
    {
      'title': 'الصور',
      'icon': Icons.camera_alt_outlined,
      'description': 'أضف صور للمحصول'
    },
    {
      'title': 'السعر والكمية',
      'icon': Icons.attach_money,
      'description': 'حدد السعر والكمية'
    },
    {
      'title': 'الموقع',
      'icon': Icons.location_on_outlined,
      'description': 'حدد موقع المحصول'
    },
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _scaleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _scaleController,
          curve: Curves.bounceOut,
        ));

    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.take(5).toList();
        }
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
        if (_selectedImages.length > 5) {
          _selectedImages.removeLast();
        }
      });
      HapticFeedback.mediumImpact();
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
    HapticFeedback.lightImpact();
  }

  Future<void> _selectLocation() async {
    final result = await context.push('/map-picker');
    if (result != null && result is LocationData) {
      setState(() => _selectedLocation = result);
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty && _selectedType.isNotEmpty;
      case 1:
        return _selectedImages.isNotEmpty;
      case 2:
        return _priceController.text.isNotEmpty &&
            _quantityController.text.isNotEmpty;
      case 3:
        return _selectedLocation != null;
      default:
        return false;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      HapticFeedback.mediumImpact();

      // Use repo directly (matches your CropsRepo API)
      final repo = ref.read(cropsRepoProvider);
      await repo.create(
        name: _nameController.text,
        type: _selectedType, // repo expects "type"
        qty: double.parse(_quantityController.text), // repo expects "qty"
        price: double.parse(_priceController.text),
        unit: _selectedUnit,
        location: _selectedLocation!, // LocationData
        notes: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text, // repo expects "notes"
        images: _selectedImages.map((x) => File(x.path)).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المحصول بنجاح! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة المحصول: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // correct loading flags from CropsState (no isLoading getter)
    final s = ref.watch(cropsControllerProvider);
    final isLoading = s.loading || s.loadingMore;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 20),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'إضافة محصول جديد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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

          // Progress header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: List.generate(_steps.length, (index) {
                      final isActive = index <= _currentStep;
                      final isCompleted = index < _currentStep;
                      return Expanded(
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? Colors.green
                                    : isActive
                                    ? theme.colorScheme.primary
                                    : Colors.grey[300],
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.check
                                    : _steps[index]['icon'],
                                color: isActive || isCompleted
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 16,
                              ),
                            ),
                            if (index < _steps.length - 1)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: index < _currentStep
                                        ? Colors.green
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_currentStep),
                      children: [
                        Text(
                          _steps[_currentStep]['title'],
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _steps[_currentStep]['description'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content (each page scrolls internally → no overflow)
          SliverFillRemaining(
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _basicInfoStepScrollable(),
                    _imagesStepScrollable(),
                    _priceQuantityStepScrollable(),
                    _locationStepScrollable(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // FABs
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentStep > 0)
            FloatingActionButton.extended(
              onPressed: _previousStep,
              heroTag: 'back',
              backgroundColor: Colors.grey[600],
              icon: const Icon(Icons.arrow_back),
              label: const Text('السابق'),
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: isLoading
                ? null
                : _currentStep == _steps.length - 1
                ? _submitForm
                : _canProceedToNextStep()
                ? _nextStep
                : null,
            heroTag: 'next',
            backgroundColor:
            _canProceedToNextStep() || _currentStep == _steps.length - 1
                ? theme.colorScheme.primary
                : Colors.grey[400],
            icon: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Icon(_currentStep == _steps.length - 1
                ? Icons.check
                : Icons.arrow_forward),
            label: Text(_currentStep == _steps.length - 1 ? 'إنشاء' : 'التالي'),
          ),
        ],
      ),
    );
  }

  /// ------- Steps (scrollable Lists to avoid RenderFlex overflow) -------

  Widget _basicInfoStepScrollable() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAnimatedCard(
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المحصول *',
                  hintText: 'مثال: طماطم حمراء طازجة',
                  prefixIcon: Icon(Icons.agriculture),
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'اسم المحصول مطلوب' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  hintText: 'وصف تفصيلي للمحصول وجودته',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedCard(
          delay: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نوع المحصول *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cropTypes.map((type) {
                  final isSelected = _selectedType == type;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(type),
                    onSelected: (_) {
                      setState(() => _selectedType = type);
                      HapticFeedback.selectionClick();
                    },
                    selectedColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagesStepScrollable() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAnimatedCard(
          child: Column(
            children: [
              if (_selectedImages.isEmpty) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'أضف صور للمحصول',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'يمكنك إضافة حتى 5 صور',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (index == 0)
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                                  ),
                                  child: const Text(
                                    'رئيسية',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                      _selectedImages.length < 5 ? _pickImages : null,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('من المعرض'),
                      style: ElevatedButton.styleFrom(
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
                      onPressed:
                      _selectedImages.length < 5 ? _takePicture : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('التقاط صورة'),
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
            ],
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAnimatedCard(
            delay: 200,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الصورة الأولى ستكون الصورة الرئيسية للمحصول',
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _priceQuantityStepScrollable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On narrow cards/phones, stack fields vertically to avoid overflow.
        final bool narrow = constraints.maxWidth < 360;

        InputDecoration denseDecoration({
          required String label,
          IconData? prefix,
        }) {
          return InputDecoration(
            labelText: label,
            // tighten vertical space so fields fit better
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: prefix != null ? Icon(prefix) : null,
            // keep prefix icon narrow so it doesn't eat width
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAnimatedCard(
              child: Column(
                children: [
                  // PRICE
                  TextFormField(
                    controller: _priceController,
                    decoration: denseDecoration(
                      label: 'السعر (جنيه سوداني) *',
                      prefix: Icons.attach_money,
                    ),
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr, // numbers look better LTR
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'السعر مطلوب';
                      if (double.tryParse(value) == null) return 'سعر غير صحيح';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 16),

                  // QUANTITY + UNIT
                  if (narrow)
                  // Vertical layout (no overflow)
                    Column(
                      children: [
                        TextFormField(
                          controller: _quantityController,
                          decoration: denseDecoration(
                            label: 'الكمية *',
                            prefix: Icons.inventory,
                          ),
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'الكمية مطلوبة';
                            if (double.tryParse(value) == null) return 'كمية غير صحيحة';
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          isExpanded: true, // <— important to avoid row overflow
                          decoration: denseDecoration(
                            label: 'الوحدة',
                            prefix: Icons.straighten,
                          ),
                          items: _units
                              .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _selectedUnit = value);
                          },
                        ),
                      ],
                    )
                  else
                  // Horizontal layout (roomy screens)
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: denseDecoration(
                              label: 'الكمية *',
                              prefix: Icons.inventory,
                            ),
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'الكمية مطلوبة';
                              if (double.tryParse(value) == null) return 'كمية غير صحيحة';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            isExpanded: true, // <— important
                            decoration: denseDecoration(
                              label: 'الوحدة',
                              prefix: Icons.straighten,
                            ),
                            items: _units
                                .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _selectedUnit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary card
            if (_priceController.text.isNotEmpty && _quantityController.text.isNotEmpty)
              _buildAnimatedCard(
                delay: 200,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('ملخص السعر',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('السعر للوحدة الواحدة:'),
                          Text(
                            '${_priceController.text} جنيه',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('إجمالي القيمة:'),
                          Text(
                            '${(double.tryParse(_priceController.text) ?? 0) * (double.tryParse(_quantityController.text) ?? 0)} جنيه',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _locationStepScrollable() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAnimatedCard(
          child: Column(
            children: [
              if (_selectedLocation == null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'حدد موقع المحصول',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اختر الموقع على الخريطة',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'الموقع المحدد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  _selectedLocation!.address ?? 'السودان',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.gps_fixed,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'خط العرض: ${_selectedLocation!.lat.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.gps_fixed,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'خط الطول: ${_selectedLocation!.lng.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectLocation,
                  icon: Icon(_selectedLocation == null
                      ? Icons.location_on
                      : Icons.edit_location),
                  label: Text(_selectedLocation == null
                      ? 'اختيار الموقع'
                      : 'تغيير الموقع'),
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
      ],
    );
  }

  /// ------- Shared card animation -------

  Widget _buildAnimatedCard({required Widget child, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
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
      ),
    );
  }
}
