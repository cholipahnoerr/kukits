import 'package:firebase_auth/firebase_auth.dart';
import '../domain/user_model.dart';
import 'auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepository({AuthRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? AuthRemoteDataSource();

  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  Future<UserModel> login(String email, String password) =>
      _dataSource.login(email, password);

  Future<UserModel> register(String name, String email, String password) =>
      _dataSource.register(name, email, password);

  Future<UserModel> loginWithGoogle() => _dataSource.loginWithGoogle();

  Future<void> logout() => _dataSource.logout();

  Future<void> sendPasswordResetEmail(String email) =>
      _dataSource.sendPasswordResetEmail(email);

  Future<UserModel> getUserById(String uid) => _dataSource.getUserById(uid);
}