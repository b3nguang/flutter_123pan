import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import '../services/config_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ConfigService configService;
  AppSettings _settings = const AppSettings(defaultDownloadPath: '');

  SettingsProvider({required this.configService});

  AppSettings get settings => _settings;
  String get defaultDownloadPath => _settings.defaultDownloadPath;
  bool get askDownloadLocation => _settings.askDownloadLocation;

  Future<void> load() async {
    final config = await configService.loadConfig();
    _settings = config.settings;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    final config = await configService.loadConfig();
    await configService.saveConfig(config.copyWith(settings: newSettings));
  }
}
