import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_page.dart';
import 'product_manage_page.dart';
import 'user_list_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colorScheme.primary,
                  child: Icon(Icons.person,
                      size: 40, color: colorScheme.onPrimary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('用户',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('欢迎使用电商App',
                        style: TextStyle(
                            fontSize: 13, color: colorScheme.outline)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildOrderSection(context),
          const SizedBox(height: 8),
          _buildMenuSection(context),
          const SizedBox(height: 8),
          _buildAdminSection(context),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => _logout(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('退出登录', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOrderSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('我的订单',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOrderIcon(Icons.payment, '待付款'),
                _buildOrderIcon(Icons.local_shipping_outlined, '待发货'),
                _buildOrderIcon(Icons.inventory_2_outlined, '待收货'),
                _buildOrderIcon(Icons.rate_review_outlined, '待评价'),
                _buildOrderIcon(Icons.assignment_return_outlined, '退换货'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildMenuItem(Icons.location_on_outlined, '收货地址'),
          _buildMenuItem(Icons.favorite_border, '我的收藏'),
          _buildMenuItem(Icons.history, '浏览记录'),
          _buildMenuItem(Icons.headset_mic_outlined, '客服中心'),
          _buildMenuItem(Icons.settings_outlined, '设置'),
        ],
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('管理',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('用户管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserListPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('商品管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductManagePage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false)),
          TextButton(
              child: const Text('退出'),
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
