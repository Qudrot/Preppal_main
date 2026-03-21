import 'package:flutter_test/flutter_test.dart';
import 'package:prepal2/data/models/auth/user_model.dart';
import 'package:prepal2/domain/repositories/auth_repository.dart';
import 'package:prepal2/domain/usercases/login_usercase.dart';
import 'package:prepal2/domain/usercases/signup_usercase.dart';
import 'package:prepal2/presentation/providers/auth_provider.dart';
import 'package:prepal2/core/di/service_locator.dart';
import 'package:prepal2/data/datasources/auth_remote_datasource.dart';

// simple fake implementations to satisfy dependencies
class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> getLoggedInUser() async => null;

  @override
  Future<UserModel> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> signup({
    required String username,
    required String email,
    required String password,
    required String businessName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}

class _FakeRemote implements AuthRemoteDataSource {
  bool called = false;

  // all other methods are unused in these tests
  @override
  Future<Map<String, dynamic>> register({required String email, required String username, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<String> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> forgotPassword(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetPassword({required String email, required String password}) {
    throw UnimplementedError();
  }
}

void main() {
  late AuthProvider provider;
  late _FakeRemote fakeRemote;

  setUp(() {
    final repo = _FakeAuthRepository();
    provider = AuthProvider(
      loginUseCase: LoginUseCase(repository: repo),
      signupUseCase: SignupUseCase(repository: repo),
      authRepository: repo,
    );

    fakeRemote = _FakeRemote();
    // override service locator
    serviceLocator.authRemoteDataSourceForTest = fakeRemote;
  });

  test('auth provider initializes with correct status', () {
    expect(provider.status, AuthStatus.loading);
  });
}
