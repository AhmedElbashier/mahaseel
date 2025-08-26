
// lib/features/auth/state/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';
import '../data/auth_repo.dart';

/// ---- Minimal user model the UI can rely on ----
class AppUser {
  final String id;
  final String name;
  final String phone;
  final String role; // e.g. 'seller' | 'buyer' | 'admin'
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  AppUser copyWith({String? id, String? name, String? phone, String? role}) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
    );
  }
}

/// ---- Auth state your UI consumes ----
class AuthState {
  final bool isAuthenticated;
  final bool loading;
  final String? error;
  final String? devOtp; // show-only in dev
  final String? phone;
  final AppUser? user;
  final Map<String, dynamic>? pendingOAuthData; // For OAuth completion flow

  const AuthState({
    this.isAuthenticated = false,
    this.loading = false,
    this.error,
    this.devOtp,
    this.phone,
    this.user,
    this.pendingOAuthData,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? loading,
    String? error,
    String? devOtp,
    String? phone,
    AppUser? user,
    Map<String, dynamic>? pendingOAuthData,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      loading: loading ?? this.loading,
      error: error,
      devOtp: devOtp,
      phone: phone ?? this.phone,
      user: user,
      pendingOAuthData: pendingOAuthData,
    );
  }
}

final authRepoProvider = Provider((_) => AuthRepo());

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(const AuthState()) {
    _bootstrap();
    ApiClient().onUnauthorized = _handleUnauthorized;
  }
  final Ref ref;

  /// On app start, if we already have a token → mark authenticated and load profile.
  Future<void> _bootstrap() async {
    final has = await ApiClient().hasToken();
    state = state.copyWith(isAuthenticated: has);
    if (has) {
      await _loadProfile(); // try to populate user for UI
    }
  }

  Future<void> startLogin(String phone) async {
    state = state.copyWith(loading: true, error: null, phone: phone);
    try {
      final devOtp = await ref.read(authRepoProvider).login(phone: phone);
      state = state.copyWith(loading: false, devOtp: devOtp);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> startSignup({required String name, required String phone}) async {
    state = state.copyWith(loading: true, error: null, phone: phone);
    try {
      await ref.read(authRepoProvider).register(phone: phone, name: name);
      // After successful registration, start login process
      final devOtp = await ref.read(authRepoProvider).login(phone: phone);
      state = state.copyWith(loading: false, devOtp: devOtp);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> verifyOtp(String otp) async {
    final phone = state.phone!;
    state = state.copyWith(loading: true, error: null);
    try {
      final token =
      await ref.read(authRepoProvider).verify(phone: phone, otp: otp);

      // IMPORTANT: Save token before any follow-up calls
      await ApiClient().saveToken(token);

      // Mark authenticated, then load user profile
      state = state.copyWith(
        loading: false,
        isAuthenticated: true,
        devOtp: null,
      );

      await _loadProfile(); // populate state.user for UI (name/role/phone)
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// OAuth Login Methods
  Future<void> loginWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      // TODO: Implement actual Google OAuth
      // For now, simulate OAuth data
      await Future.delayed(const Duration(seconds: 1));

      // Mock OAuth response
      final oauthData = {
        'email': 'user@gmail.com',
        'name': 'Google User',
        'provider': 'google',
        'provider_id': '123456789',
      };

      // Check if user exists with this OAuth account
      // If not, redirect to complete profile
      state = state.copyWith(
        loading: false,
        pendingOAuthData: oauthData,
      );

      // Navigate to OAuth details screen - handled by UI
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loginWithFacebook() async {
    state = state.copyWith(loading: true, error: null);
    try {
      // TODO: Implement actual Facebook OAuth
      // For now, simulate OAuth data
      await Future.delayed(const Duration(seconds: 1));

      // Mock OAuth response
      final oauthData = {
        'email': 'user@facebook.com',
        'name': 'Facebook User',
        'provider': 'facebook',
        'provider_id': '987654321',
      };

      state = state.copyWith(
        loading: false,
        pendingOAuthData: oauthData,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signupWithGoogle() async {
    await loginWithGoogle(); // Same flow for now
  }

  Future<void> signupWithFacebook() async {
    await loginWithFacebook(); // Same flow for now
  }

  Future<void> completeOAuthSignup({
    required String provider,
    required Map<String, dynamic> oauthData,
    required String name,
    required String phone,
  }) async {
    state = state.copyWith(loading: true, error: null, phone: phone);
    try {
      // TODO: Send OAuth data + phone to backend for account creation
      await ref.read(authRepoProvider).register(phone: phone, name: name);

      // Start phone verification
      final devOtp = await ref.read(authRepoProvider).login(phone: phone);
      state = state.copyWith(loading: false, devOtp: devOtp);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await ApiClient().clearToken();
    state = const AuthState(); // clears everything (including user)
  }

  /// Triggered when [ApiClient] receives a 401/403 response.
  Future<void> _handleUnauthorized() async {
    state = const AuthState();
  }

  /// ---- Load profile from backend (or build minimal local user) ----
  Future<void> _loadProfile() async {
    try {
      final phone = state.phone ?? '9xxxxxxx';
      final user = AppUser(
        id: 'self',
        name: 'مستخدم محاصيل',
        phone: phone,
        role: 'seller',
      );
      state = state.copyWith(user: user);
    } catch (_) {
      state = state.copyWith(user: null);
    }
  }
}
