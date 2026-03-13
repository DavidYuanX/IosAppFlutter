import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showAlert('请输入用户名和密码');
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.instance.login(username, password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      _showAlert(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showAlert(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.storefront,
                    size: 40, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 16),
              const Text(
                '欢迎登录',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('登录后享受更多功能',
                  style: TextStyle(color: colorScheme.outline)),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('登录', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
