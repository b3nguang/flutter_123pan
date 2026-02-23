class AppSettings {
  final String defaultDownloadPath;
  final bool askDownloadLocation;

  const AppSettings({
    required this.defaultDownloadPath,
    this.askDownloadLocation = true,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultDownloadPath: json['defaultDownloadPath'] as String? ?? '',
      askDownloadLocation: json['askDownloadLocation'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultDownloadPath': defaultDownloadPath,
        'askDownloadLocation': askDownloadLocation,
      };

  AppSettings copyWith({String? defaultDownloadPath, bool? askDownloadLocation}) {
    return AppSettings(
      defaultDownloadPath: defaultDownloadPath ?? this.defaultDownloadPath,
      askDownloadLocation: askDownloadLocation ?? this.askDownloadLocation,
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
