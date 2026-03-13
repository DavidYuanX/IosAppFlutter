import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'main_shell.dart';
import 'order_list_page.dart';
import 'product_manage_page.dart';
import 'user_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _username;
  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    await ApiService.instance.isLoggedIn();
    setState(() {
      _username = ApiService.instance.currentUsername;
      _isAdmin = ApiService.instance.isAdmin;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context, colorScheme),
          const SizedBox(height: 12),
          // _buildStatsRow(context, colorScheme), // 隐藏优惠券模块
          _buildOrderSection(context, colorScheme),
          const SizedBox(height: 12),
          _buildMenuSection(context, colorScheme),
          if (_isAdmin) ...[
            const SizedBox(height: 12),
            _buildAdminSection(context, colorScheme),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => _logout(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withOpacity(0.3)),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('退出登录', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final username = _username ?? '用户';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person,
                          size: 38, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi，$username',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAdmin ? Icons.admin_panel_settings : Icons.diamond_outlined,
                                size: 14,
                                color: _isAdmin ? Colors.cyanAccent : Colors.amberAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAdmin ? '管理员' : '普通会员',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('优惠券', '3', colorScheme),
          _divider(colorScheme),
          _statItem('积分', '1280', colorScheme),
          _divider(colorScheme),
          _statItem('余额', '¥0', colorScheme),
          _divider(colorScheme),
          _statItem('会员', 'Lv.1', colorScheme),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: colorScheme.outline)),
      ],
    );
  }

  Widget _divider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 28,
      color: colorScheme.outline.withOpacity(0.1),
    );
  }

  Widget _buildOrderSection(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              const Text('我的订单',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderListPage()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('全部订单',
                        style: TextStyle(
                            fontSize: 13, color: colorScheme.outline)),
                    Icon(Icons.chevron_right,
                        size: 18, color: colorScheme.outline),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderIcon(context, Icons.access_time_rounded,
                  Colors.orange, '待付款'),
              _buildOrderIcon(context, Icons.inventory_2_outlined,
                  Colors.blue, '待发货'),
              _buildOrderIcon(context, Icons.local_shipping_outlined,
                  Colors.teal, '待收货'),
              _buildOrderIcon(context, Icons.check_circle_outline,
                  Colors.green, '已完成'),
              _buildOrderIcon(context, Icons.cancel_outlined,
                  Colors.grey, '已取消'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderIcon(
      BuildContext context, IconData icon, Color color, String label) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => OrderListPage(initialStatus: label)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
              context, Icons.location_on_outlined, Colors.blue, '收货地址'),
          _menuDivider(colorScheme),
          _buildMenuItem(
              context, Icons.favorite_border, Colors.pink, '我的收藏'),
          _menuDivider(colorScheme),
          _buildMenuItem(context, Icons.history, Colors.orange, '浏览记录'),
          _menuDivider(colorScheme),
          _buildMenuItem(
              context, Icons.headset_mic_outlined, Colors.teal, '客服中心'),
        ],
      ),
    );
  }

  Widget _menuDivider(ColorScheme colorScheme) {
    return Divider(
      height: 0,
      indent: 56,
      color: colorScheme.outline.withOpacity(0.08),
    );
  }

  Widget _buildAdminSection(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                const Text('管理中心',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _buildMenuItem(
              context, Icons.people_outline, Colors.indigo, '用户管理',
              onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserListPage()),
                  )),
          _menuDivider(colorScheme),
          _buildMenuItem(
              context, Icons.inventory_2_outlined, Colors.deepOrange, '商品管理',
              onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProductManagePage()),
                  )),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, Color color, String title,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Icon(Icons.chevron_right,
          size: 20, color: Theme.of(context).colorScheme.outline),
      onTap: onTap ?? () {},
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
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }
}
