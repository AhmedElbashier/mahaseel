// lib/features/auth/state/auth_controller.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  /// NEW: user (nullable). When null => not logged in / not loaded yet.
  final AppUser? user;

  const AuthState({
    this.isAuthenticated = false,
    this.loading = false,
    this.error,
    this.devOtp,
    this.phone,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? loading,
    String? error,
    String? devOtp,
    String? phone,
    AppUser? user, // pass null explicitly to clear
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
  AuthController(this.ref, this._dio) : super(const AuthState()) {
    _bootstrap();
    ApiClient().onUnauthorized = _handleUnauthorized;
  }
  final Ref ref;
  final _store = const FlutterSecureStorage();
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

  Future<void> verifyOtp(String otp) async {
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
  /// final user = AppUser(id: dto.id, name: dto.name, phone: dto.phone, role: dto.role);
  Future<void> _loadProfile() async {
    try {
      // If you have an endpoint, call it here and map to AppUser.
      // For now, build a minimal user using the known phone or a placeholder.
      final phone = state.phone ?? '9xxxxxxx';
      // You can also persist "name/role" server-side and fetch them.
      final user = AppUser(
        id: 'self', // replace with real id
        name: 'مستخدم محاصيل', // replace with server name
        phone: phone,
        role: 'seller', // replace with server role
      );
      state = state.copyWith(user: user);
    } catch (_) {
      // If profile fails, keep authenticated but no user (UI should handle nulls safely).
      state = state.copyWith(user: null);
    }
  }

  Future<void> loginWithGoogle() async {
    final gs = GoogleSignIn(scopes: ['email', 'profile']);
    final acc = await gs.signIn();
    final auth = await acc?.authentication;
    final idToken = auth?.idToken;
    if (idToken == null) throw Exception('No Google ID token');
    final res = await _dio.post(
      '/auth/social/google',
      data: {'token': idToken},
    );
    final temp = res.data['access_token'] as String;
    await _store.write(key: 'token', value: temp);
  }

  Future<void> loginWithFacebook() async {
    final result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
    );
    if (result.status != LoginStatus.success)
      throw Exception('FB login cancelled');
    final accessToken = result.accessToken!.token;
    final res = await _dio.post(
      '/auth/social/facebook',
      data: {'token': accessToken},
    );
    final temp = res.data['access_token'] as String;
    await _store.write(key: 'token', value: temp);
  }

  Future<Map<String, dynamic>> me() async {
    final t = await _store.read(key: 'token');
    if (t == null) throw Exception('no token');
    final r = await _dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );
    return Map<String, dynamic>.from(r.data);
  }

  Future<void> linkPhone(String phone) async {
    final t = await _store.read(key: 'token');
    final r = await _dio.post(
      '/auth/link-phone',
      data: {'phone': phone},
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );
    // show r.data['code'] in dev
  }

  Future<void> verifyOtp(String phone, String code) async {
    final t = await _store.read(key: 'token');
    final r = await _dio.post(
      '/auth/verify-otp',
      data: {'phone': phone, 'code': code},
      options: Options(headers: {'Authorization': 'Bearer $t'}),
    );
    final full = r.data['access_token'] as String;
    await _store.write(key: 'token', value: full);
  }

  Future<bool> isFullyAuthed() async {
    final t = await _store.read(key: 'token');
    if (t == null) return false;
    final payload = Jwt.parseJwt(t);
    return payload['scope'] == 'user';
  }
}
