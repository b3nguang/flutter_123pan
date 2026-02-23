import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart' show isMobile;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _userCtrl.text = auth.getSavedUserName();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? CatppuccinMocha.blue : CatppuccinLatte.blue;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? CatppuccinMocha.surface1 : CatppuccinLatte.surface0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile(context) ? 24 : 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_outlined, size: 56, color: accent),
                      const SizedBox(height: 12),
                      Text(
                        '123云盘',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '登录您的账户继续使用',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _userCtrl,
                        decoration: const InputDecoration(
                          labelText: '用户名 / 手机号',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '请输入用户名' : null,
                        onFieldSubmitted: (_) => _doLogin(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '请输入密码' : null,
                        onFieldSubmitted: (_) => _doLogin(),
                      ),
                      const SizedBox(height: 8),
                      Consumer<AuthProvider>(
                        builder: (_, auth, a) {
                          if (auth.state == AuthState.error &&
                              auth.errorMessage.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                auth.errorMessage,
                                style: TextStyle(
                                  color: isDark
                                      ? CatppuccinMocha.red
                                      : CatppuccinLatte.red,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Consumer<AuthProvider>(
                          builder: (_, auth, b) => ElevatedButton(
                            onPressed: auth.state == AuthState.loading
                                ? null
                                : _doLogin,
                            child: auth.state == AuthState.loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('登录',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
