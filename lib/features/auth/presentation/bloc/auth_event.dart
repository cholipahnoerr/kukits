import 'package:equatable/equatable.dart';
import '../../domain/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, password];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthStateChanged extends AuthEvent {
  final bool isLoggedIn;

  const AuthStateChanged({required this.isLoggedIn});

  @override
  List<Object> get props => [isLoggedIn];
}

class AuthUserUpdated extends AuthEvent {
  final UserModel user;
  const AuthUserUpdated(this.user);
  @override
  List<Object?> get props => [user.uid];
}