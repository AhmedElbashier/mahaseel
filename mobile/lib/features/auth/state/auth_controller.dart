// lib/features/auth/state/auth_controller.dart
import 'package:dio/dio.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
/// We keep your original fields and add [user].
class AuthState {
  final bool isAuthenticated;
  final bool loading;
  final String? error;
  final String? devOtp; // show-only in dev
  final String? phone;
  final String? scope;                   // <-- add this

  /// NEW: user (nullable). When null => not logged in / not loaded yet.
  final AppUser? user;

  const AuthState({
    this.isAuthenticated = false,
    this.loading = false,
    this.error,
    this.devOtp,
    this.phone,
    this.user,
    this.scope
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? loading,
    String? error,
    String? devOtp,
    String? phone,
    AppUser? user, // pass null explicitly to clear
    String? scope
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      loading: loading ?? this.loading,
      error: error,
      devOtp: devOtp,
      phone: phone ?? this.phone,
      user: user,
    );
  }
}

final authRepoProvider = Provider((_) => AuthRepo());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref);
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref)
      : _dio = ApiClient().dio,
        super(const AuthState()) {
    _bootstrap();
    ApiClient().onUnauthorized = _handleUnauthorized;
  }
  final Ref ref;
  final Dio _dio;

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

  Future<void> verifyLoginOtp(String otp) async {
    final phone = state.phone!;
    state = state.copyWith(loading: true, error: null);
    try {
      final token = await ref
          .read(authRepoProvider)
          .verify(phone: phone, otp: otp);

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

  Future<void> logout() async {
    await ApiClient().clearToken();
    state = const AuthState(); // clears everything (including user)
  }

  /// Triggered when [ApiClient] receives a 401/403 response.
  Future<void> _handleUnauthorized() async {
    state = const AuthState();
  }

  /// ---- Load profile from backend (or build minimal local user) ----
  ///
  /// Replace the mock below with your real API call, e.g.:
  /// final dto = await ref.read(authRepoProvider).getProfile();


  Future<void> loginWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final signIn = GoogleSignIn.instance;

      // IMPORTANT: use your Google "Web client ID" here so you get an ID token
      await signIn.initialize(
        // clientId: 'ios-client-id.apps.googleusercontent.com', // iOS only if you have it
        serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
      );

      GoogleSignInAccount? account;
      if (signIn.supportsAuthenticate()) {
        account = await signIn.authenticate(scopeHint: ['email', 'profile']);
      } else {
        // fallback (older/web platforms can try a lightweight attempt)
        account = await signIn.attemptLightweightAuthentication();
        if (account == null) throw Exception('Google Sign-In not available');
      }

      final idToken = (await account.authentication).idToken;
      if (idToken == null) throw Exception('No Google ID token (check serverClientId)');

      final res = await _dio.post('/auth/social/google', data: {'token': idToken});
      final temp = res.data['access_token'] as String;

      await ApiClient().saveToken(temp);   // temp JWT (scope=link_phone)
      await _loadProfile();                // fills user + scope from /auth/me
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }


  Future<void> loginWithFacebook() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      if (result.status != LoginStatus.success) {
        throw Exception('FB login cancelled: ${result.status}');
      }

      final accessToken = result.accessToken!.tokenString; // << changed
      final res = await _dio.post('/auth/social/facebook', data: {'token': accessToken});
      final temp = res.data['access_token'] as String;

      await ApiClient().saveToken(temp);   // temp token (scope=link_phone)
      await _loadProfile();
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> linkPhone(String phone) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final r = await _dio.post('/auth/link-phone', data: {'phone': phone});
      final devOtp = (r.data is Map<String, dynamic>) ? r.data['code'] as String? : null;
      state = state.copyWith(loading: false, devOtp: devOtp, phone: phone);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> verifyLinkOtp(String phone, String code) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final r = await _dio.post('/auth/verify-otp', data: {'phone': phone, 'code': code});
      final full = r.data['access_token'] as String;

      await ApiClient().saveToken(full);  // upgrade to full token (scope=user)
      await _loadProfile();
      state = state.copyWith(loading: false, devOtp: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
  Future<bool> isFullyAuthed() async {
    try {
      final me = await _dio.get('/auth/me');
      return (me.data['scope'] as String?) == 'user';
    } catch (_) {
      return false;
    }
  }
  Future<void> _loadProfile() async {
    try {
      final r = await _dio.get('/auth/me'); // ApiClient injects Authorization
      final data = Map<String, dynamic>.from(r.data);
      final user = AppUser(
        id: '${data['id']}',
        name: (data['name'] ?? 'مستخدم') as String,
        phone: (data['phone'] ?? '') as String,
        role: (data['role'] ?? 'seller') as String,
      );
      state = state.copyWith(user: user, scope: data['scope'] as String?, isAuthenticated: true);
    } catch (_) {
      state = state.copyWith(user: null);
    }
  }

}
