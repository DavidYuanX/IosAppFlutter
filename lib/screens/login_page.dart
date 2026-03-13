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
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  bool _isRegister = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlert('请输入用户名和密码');
      return;
    }

    if (_isRegister) {
      if (username.length < 3 || username.length > 20) {
        _showAlert('用户名长度需在3-20个字符之间');
        return;
      }
      if (password.length < 6) {
        _showAlert('密码长度至少6个字符');
        return;
      }
      if (password != _confirmPasswordController.text) {
        _showAlert('两次输入的密码不一致');
        return;
      }
      if (phone.isEmpty) {
        _showAlert('请输入手机号');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await ApiService.instance.register(username, password, phone);
      } else {
        await ApiService.instance.login(username, password);
      }
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

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _confirmPasswordController.clear();
      _phoneController.clear();
    });
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
              Text(
                _isRegister ? '创建账号' : '欢迎登录',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegister ? '注册后享受更多功能' : '登录后享受更多功能',
                style: TextStyle(color: colorScheme.outline),
              ),
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
                textInputAction: _isRegister ? TextInputAction.next : TextInputAction.done,
                onSubmitted: _isRegister ? null : (_) => _submit(),
              ),
              if (_isRegister) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: '确认密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: '手机号',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
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
                      : Text(_isRegister ? '注册' : '登录',
                          style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isRegister ? '已有账号？' : '没有账号？',
                    style: TextStyle(color: colorScheme.outline),
                  ),
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(_isRegister ? '去登录' : '去注册'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}