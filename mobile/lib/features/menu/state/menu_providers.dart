import 'package:flutter_riverpod/flutter_riverpod.dart';

// fake sources for now; later wire to real settings/auth providers
final userNameProvider = Provider<String>((_) => 'Ahmed Elbashier');
final isVerifiedProvider = Provider<bool>((_) => true);
final joinedTextProvider = Provider<String>((_) => 'انضم في فبراير 2023');

final cityProvider = StateProvider<String>((_) => 'كل الإمارات');
final languageProvider = StateProvider<String>((_) => 'العربية');
