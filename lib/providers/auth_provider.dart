import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import '../services/api_service.dart';
import '../services/config_service.dart';

enum AuthState { idle, loading, loggedIn, error }

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  final ConfigService configService;

  AuthState _state = AuthState.idle;
  String _errorMessage = '';
  String _userName = '';
  AppConfig? _config;

  AuthProvider({required this.apiService, required this.configService});

  AuthState get state => _state;
  String get errorMessage => _errorMessage;
  String get userName => _userName;
  bool get isLoggedIn => _state == AuthState.loggedIn;
  AppConfig? get config => _config;

  Future<bool> tryAutoLogin() async {
    _config = await configService.loadConfig();
    final cfg = _config!;
    if (cfg.userName.isEmpty || cfg.passWord.isEmpty) return false;

    if (cfg.deviceType.isNotEmpty) {
      apiService.setDeviceInfo(cfg.deviceType, cfg.osVersion);
    }
    if (cfg.authorization.isNotEmpty) {
      apiService.setAuthorization(cfg.authorization);
    }

    try {
      final result = await apiService.getFileList(parentFileId: 0, page: 1, limit: 1);
      if (result['code'] == 0) {
        _userName = cfg.userName;
        _state = AuthState.loggedIn;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    return await login(cfg.userName, cfg.passWord);
  }

  Future<bool> login(String userName, String password) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await apiService.login(userName, password);
      final code = result['code'] as int?;
      if (code != 200) {
        _errorMessage = result['message'] as String? ?? '登录失败，返回码: $code';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }

      final token = result['data']['token'] as String;
      final authorization = 'Bearer $token';
      apiService.setAuthorization(authorization);

      _userName = userName;
      _state = AuthState.loggedIn;

      final cfg = await configService.loadConfig();
      final newCfg = cfg.copyWith(
        userName: userName,
        passWord: password,
        authorization: authorization,
        deviceType: apiService.deviceType,
        osVersion: apiService.osVersion,
      );
      _config = newCfg;
      await configService.saveConfig(newCfg);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await configService.clearCredentials();
    apiService.setAuthorization('');
    _userName = '';
    _state = AuthState.idle;
    notifyListeners();
  }

  String getSavedUserName() {
    return _config?.userName ?? '';
  }
}
