import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthUserUpdated>((event, emit) {
      if (state is AuthAuthenticated) {
        emit(AuthAuthenticated(user: event.user));
      }
    });

    _authSubscription = _repository.authStateChanges.listen((user) {
      add(AuthStateChanged(isLoggedIn: user != null));
    });
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.login(event.email, event.password);
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user =
          await _repository.register(event.name, event.email, event.password);
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.loginWithGoogle();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _repository.sendPasswordResetEmail(event.email);
      emit(const AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    if (!event.isLoggedIn && state is! AuthLoading) {
      emit(const AuthUnauthenticated());
    }
  }

  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found' => 'Email tidak terdaftar',
        'wrong-password' => 'Kata sandi salah',
        'email-already-in-use' => 'Email sudah digunakan',
        'invalid-email' => 'Format email tidak valid',
        'weak-password' => 'Kata sandi terlalu lemah (min 6 karakter)',
        'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti',
        'network-request-failed' => 'Periksa koneksi internet Anda',
        _ => 'Terjadi kesalahan. Coba lagi',
      };

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}