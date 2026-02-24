import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/file_provider.dart';
import 'providers/transfer_provider.dart';
import 'providers/settings_provider.dart';
import 'services/api_service.dart';
import 'services/config_service.dart';
import 'services/download_service.dart';
import 'services/upload_service.dart';
import 'providers/webdav_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Pan123App());
}

class Pan123App extends StatelessWidget {
  const Pan123App({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final configService = ConfigService.instance;
    final downloadService = DownloadService();
    final uploadService = UploadService(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<ConfigService>.value(value: configService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: apiService,
            configService: configService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FileProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TransferProvider(
            apiService: apiService,
            downloadService: downloadService,
            uploadService: uploadService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(configService: configService),
        ),
        ChangeNotifierProvider(
          create: (_) => WebDavProvider(
            apiService: apiService,
            configService: configService,
          )..loadConfig(),
        ),
      ],
      child: MaterialApp(
        title: '123云盘',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const _SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    await settings.load();
    final ok = await auth.tryAutoLogin();
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_outlined, size: 72, color: accent),
            const SizedBox(height: 16),
            Text(
              '123云盘',
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: accent),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
