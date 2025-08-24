
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'كيف أقوم بإنشاء حساب جديد؟',
      answer: 'يمكنك إنشاء حساب جديد عن طريق إدخال رقم هاتفك والتحقق منه برمز OTP الذي سيتم إرساله إليك.',
      category: 'الحساب',
    ),
    FAQItem(
      question: 'كيف أضيف محصول جديد؟',
      answer: 'اذهب إلى صفحة المحاصيل واضغط على زر "+" لإضافة محصول جديد. قم بملء جميع المعلومات المطلوبة وإضافة صور.',
      category: 'المحاصيل',
    ),
    FAQItem(
      question: 'كيف أتواصل مع المشتري؟',
      answer: 'يمكنك التواصل مع المشتري عن طريق الضغط على زر "تواصل عبر واتساب" في صفحة تفاصيل المحصول.',
      category: 'التواصل',
    ),
    FAQItem(
      question: 'كيف أحدث معلومات المحصول؟',
      answer: 'اذهب إلى محاصيلي، اختر المحصول المراد تحديثه، واضغط على "تحرير" لتعديل المعلومات.',
      category: 'المحاصيل',
    ),
    FAQItem(
      question: 'هل يمكنني حذف محصول منشور؟',
      answer: 'نعم، يمكنك حذف المحصول من صفحة محاصيلي عن طريق الضغط على أيقونة الحذف.',
      category: 'المحاصيل',
    ),
    FAQItem(
      question: 'كيف أغير رقم هاتفي؟',
      answer: 'حالياً لا يمكن تغيير رقم الهاتف. يرجى التواصل مع الدعم الفني لمساعدتك.',
      category: 'الحساب',
    ),
    FAQItem(
      question: 'لماذا لا تظهر محاصيلي؟',
      answer: 'تأكد من اتصالك بالإنترنت وأن المحاصيل قد تم حفظها بنجاح. إذا استمرت المشكلة، أعد تشغيل التطبيق.',
      category: 'مشاكل تقنية',
    ),
    FAQItem(
      question: 'كيف أقيم البائع؟',
      answer: 'بعد التواصل مع البائع، ستظهر لك خيار لتقييمه في صفحة تفاصيل المحصول.',
      category: 'التقييمات',
    ),
  ];

  List<FAQItem> get _filteredFAQs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((faq) =>
    faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        faq.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'الدعم والمساعدة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.green[700],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              const SizedBox(height: 20),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 20),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 20),

              // FAQ Categories
              _buildFAQSection(),
              const SizedBox(height: 20),

              // Contact Options
              _buildContactSection(),
              const SizedBox(height: 20),

              // App Info
              _buildAppInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[400]!],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.support_agent,
            color: Colors.white,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'مرحباً بك في الدعم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'نحن هنا لمساعدتك في استخدام محاصيل بأفضل طريقة ممكنة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'اتصل بنا',
                Icons.phone,
                Colors.blue,
                    () => _makePhoneCall('+249123456789'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                'واتساب',
                Icons.chat,
                Colors.green,
                    () => _openWhatsApp('+249123456789'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                'بريد إلكتروني',
                Icons.email,
                Colors.orange,
                    () => _sendEmail('support@mahaseel.com'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'ابحث في الأسئلة الشائعة...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final categories = _filteredFAQs.map((faq) => faq.category).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأسئلة الشائعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...categories.map((category) => _buildCategorySection(category)).toList(),
      ],
    );
  }

  Widget _buildCategorySection(String category) {
    final categoryFAQs = _filteredFAQs.where((faq) => faq.category == category).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(category),
                  color: Colors.green[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          ...categoryFAQs.map((faq) => _buildFAQItem(faq)).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            faq.answer,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_support, color: Colors.green[700]),
              const SizedBox(width: 10),
              Text(
                'تواصل معنا',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildContactItem(
            'الهاتف',
            '+249 123 456 789',
            Icons.phone,
                () => _makePhoneCall('+249123456789'),
          ),
          _buildContactItem(
            'واتساب',
            '+249 123 456 789',
            Icons.chat,
                () => _openWhatsApp('+249123456789'),
          ),
          _buildContactItem(
            'البريد الإلكتروني',
            'support@mahaseel.com',
            Icons.email,
                () => _sendEmail('support@mahaseel.com'),
          ),
          _buildContactItem(
            'ساعات العمل',
            'الأحد - الخميس: 8:00 ص - 6:00 م',
            Icons.schedule,
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String title, String value, IconData icon, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.green[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green[700]),
              const SizedBox(width: 10),
              Text(
                'معلومات التطبيق',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoRow('إصدار التطبيق', 'v1.0.0'),
          _buildInfoRow('آخر تحديث', '2025-01-01'),
          _buildInfoRow('المطور', 'فريق محاصيل'),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('إرسال تعليق أو اقتراح'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'الحساب':
        return Icons.account_circle;
      case 'المحاصيل':
        return Icons.agriculture;
      case 'التواصل':
        return Icons.chat;
      case 'التقييمات':
        return Icons.star;
      case 'مشاكل تقنية':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorMessage('لا يمكن فتح تطبيق الهاتف');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber?text=مرحبا، أحتاج مساعدة في تطبيق محاصيل');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      _showErrorMessage('لا يمكن فتح واتساب');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=مساعدة في تطبيق محاصيل&body=مرحبا، أحتاج مساعدة في:',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorMessage('لا يمكن فتح تطبيق البريد الإلكتروني');
    }
  }

  void _submitFeedback() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إرسال تعليق'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'موضوع التعليق',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'تفاصيل التعليق أو الاقتراح',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessMessage('تم إرسال تعليقك بنجاح');
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class FAQItem {
  final String question;
  final String answer;
  final String category;

  FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}
