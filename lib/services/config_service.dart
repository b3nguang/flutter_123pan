import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/app_config.dart';

class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance ??= ConfigService._();
  ConfigService._();

  Future<String> get _configDir async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      return p.join(appData, 'Qxyz17', '123pan');
    } else {
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, '.config', 'Qxyz17', '123pan');
    }
  }

  Future<String> get _configFile async {
    final dir = await _configDir;
    return p.join(dir, 'config.json');
  }

  Future<String> get _defaultDownloadsPath async {
    try {
      final dir = await getDownloadsDirectory();
      return dir?.path ?? p.join(Platform.environment['USERPROFILE'] ?? '', 'Downloads');
    } catch (_) {
      return p.join(Platform.environment['USERPROFILE'] ?? '', 'Downloads');
    }
  }

  Future<AppConfig> loadConfig() async {
    try {
      final filePath = await _configFile;
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        var config = AppConfig.fromJson(json);
        if (config.settings.defaultDownloadPath.isEmpty) {
          final downloadsPath = await _defaultDownloadsPath;
          config = config.copyWith(
            settings: config.settings.copyWith(defaultDownloadPath: downloadsPath),
          );
        }
        return config;
      }
    } catch (_) {}
    final downloadsPath = await _defaultDownloadsPath;
    return AppConfig.defaultConfig(downloadsPath);
  }

  Future<void> saveConfig(AppConfig config) async {
    try {
      final filePath = await _configFile;
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(config.toJson()), flush: true);
    } catch (_) {}
  }

  Future<void> clearCredentials() async {
    final config = await loadConfig();
    await saveConfig(config.copyWith(
      userName: '',
      passWord: '',
      authorization: '',
    ));
  }
}
