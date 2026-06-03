import 'package:equatable/equatable.dart';
import '../../domain/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user.uid];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}