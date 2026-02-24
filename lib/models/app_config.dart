class WebDavConfig {
  final bool enabled;
  final int port;
  final String username;
  final String password;
  final String basePath;

  const WebDavConfig({
    this.enabled = false,
    this.port = 8090,
    this.username = '',
    this.password = '',
    this.basePath = '/dav',
  });

  factory WebDavConfig.fromJson(Map<String, dynamic> json) {
    return WebDavConfig(
      enabled: json['enabled'] as bool? ?? false,
      port: json['port'] as int? ?? 8090,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      basePath: json['basePath'] as String? ?? '/dav',
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'port': port,
        'username': username,
        'password': password,
        'basePath': basePath,
      };

  WebDavConfig copyWith({
    bool? enabled,
    int? port,
    String? username,
    String? password,
    String? basePath,
  }) {
    return WebDavConfig(
      enabled: enabled ?? this.enabled,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      basePath: basePath ?? this.basePath,
    );
  }
}

class AppSettings {
  final String defaultDownloadPath;
  final bool askDownloadLocation;
  final WebDavConfig webDav;

  const AppSettings({
    required this.defaultDownloadPath,
    this.askDownloadLocation = true,
    this.webDav = const WebDavConfig(),
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultDownloadPath: json['defaultDownloadPath'] as String? ?? '',
      askDownloadLocation: json['askDownloadLocation'] as bool? ?? true,
      webDav: json['webDav'] != null
          ? WebDavConfig.fromJson(json['webDav'] as Map<String, dynamic>)
          : const WebDavConfig(),
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultDownloadPath': defaultDownloadPath,
        'askDownloadLocation': askDownloadLocation,
        'webDav': webDav.toJson(),
      };

  AppSettings copyWith({
    String? defaultDownloadPath,
    bool? askDownloadLocation,
    WebDavConfig? webDav,
  }) {
    return AppSettings(
      defaultDownloadPath: defaultDownloadPath ?? this.defaultDownloadPath,
      askDownloadLocation: askDownloadLocation ?? this.askDownloadLocation,
      webDav: webDav ?? this.webDav,
    );
  }
}

class AppConfig {
  final String userName;
  final String passWord;
  final String authorization;
  final String deviceType;
  final String osVersion;
  final AppSettings settings;

  const AppConfig({
    this.userName = '',
    this.passWord = '',
    this.authorization = '',
    this.deviceType = '',
    this.osVersion = '',
    required this.settings,
  });

  factory AppConfig.defaultConfig(String downloadsPath) {
    return AppConfig(
      settings: AppSettings(defaultDownloadPath: downloadsPath),
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      userName: json['userName'] as String? ?? '',
      passWord: json['passWord'] as String? ?? '',
      authorization: json['authorization'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? '',
      osVersion: json['osVersion'] as String? ?? '',
      settings: json['settings'] != null
          ? AppSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : const AppSettings(defaultDownloadPath: ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'passWord': passWord,
        'authorization': authorization,
        'deviceType': deviceType,
        'osVersion': osVersion,
        'settings': settings.toJson(),
      };

  AppConfig copyWith({
    String? userName,
    String? passWord,
    String? authorization,
    String? deviceType,
    String? osVersion,
    AppSettings? settings,
  }) {
    return AppConfig(
      userName: userName ?? this.userName,
      passWord: passWord ?? this.passWord,
      authorization: authorization ?? this.authorization,
      deviceType: deviceType ?? this.deviceType,
      osVersion: osVersion ?? this.osVersion,
      settings: settings ?? this.settings,
    );
  }
}
