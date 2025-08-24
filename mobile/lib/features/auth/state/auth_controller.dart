// lib/features/auth/state/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';
import '../data/auth_repo.dart';

class AuthState {
  final bool isAuthenticated;
  final bool loading;
  final String? error;
  final String? devOtp; // show-only in dev
  final String? phone;

  AuthState({this.isAuthenticated=false, this.loading=false, this.error, this.devOtp, this.phone});

  AuthState copyWith({
    bool? isAuthenticated, bool? loading, String? error, String? devOtp, String? phone,
  }) => AuthState(
    isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    loading: loading ?? this.loading,
    error: error,
    devOtp: devOtp,
    phone: phone ?? this.phone,
  );
}

final authRepoProvider = Provider((_) => AuthRepo());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref): super(AuthState()){
    _bootstrap();
    ApiClient().onUnauthorized = _handleUnauthorized;
  }
  final Ref ref;

  Future<void> _bootstrap() async {
    final has = await ApiClient().hasToken();
    state = state.copyWith(isAuthenticated: has);
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
      final token = await ref.read(authRepoProvider).verify(phone: phone, otp: otp);
      await ApiClient().saveToken(token);      // <-- keep this HERE
      state = state.copyWith(loading: false, isAuthenticated: true, devOtp: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await ApiClient().clearToken();
    state = AuthState();
  }

  /// Triggered when [ApiClient] receives a 401/403 response.
  Future<void> _handleUnauthorized() async {
    state = AuthState();
  }
}
