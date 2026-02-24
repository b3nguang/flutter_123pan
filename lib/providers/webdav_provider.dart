import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import '../services/api_service.dart';
import '../services/config_service.dart';
import '../services/webdav_service.dart';

enum WebDavState { stopped, starting, running, error }

class WebDavProvider extends ChangeNotifier {
  final ApiService apiService;
  final ConfigService configService;

  final WebDavService _service = WebDavService();

  WebDavState _state = WebDavState.stopped;
  String _errorMessage = '';
  WebDavConfig _config = const WebDavConfig();
  String _serverUrl = '';

  WebDavProvider({required this.apiService, required this.configService});

  WebDavState get state => _state;
  bool get isRunning => _state == WebDavState.running;
  String get errorMessage => _errorMessage;
  int get port => _service.port;
  WebDavConfig get config => _config;
  String get serverUrl => _serverUrl;

  Future<String> _buildServerUrl() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      final ip = interfaces.isNotEmpty
          ? interfaces.first.addresses.first.address
          : '127.0.0.1';
      final base = _config.basePath.startsWith('/') ? _config.basePath : '/${_config.basePath}';
      return 'http://$ip:${_service.port}$base';
    } catch (_) {
      final base = _config.basePath.startsWith('/') ? _config.basePath : '/${_config.basePath}';
      return 'http://127.0.0.1:${_service.port}$base';
    }
  }

  Future<void> loadConfig() async {
    final appConfig = await configService.loadConfig();
    _config = appConfig.settings.webDav;
    notifyListeners();
  }

  Future<void> saveConfig(WebDavConfig cfg) async {
    _config = cfg;
    final appConfig = await configService.loadConfig();
    await configService.saveConfig(
      appConfig.copyWith(
        settings: appConfig.settings.copyWith(webDav: cfg),
      ),
    );
    notifyListeners();
  }

  Future<void> start() async {
    _state = WebDavState.starting;
    _errorMessage = '';
    _serverUrl = '';
    notifyListeners();
    try {
      await _service.start(
        port: _config.port,
        basePath: _config.basePath,
        username: _config.username,
        password: _config.password,
        apiService: apiService,
      );
      _serverUrl = await _buildServerUrl();
      _state = WebDavState.running;
    } catch (e) {
      _errorMessage = e.toString();
      _state = WebDavState.error;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _service.stop();
    _serverUrl = '';
    _state = WebDavState.stopped;
    notifyListeners();
  }

  Future<void> toggle() async {
    if (isRunning) {
      await stop();
    } else {
      await start();
    }
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }
}
