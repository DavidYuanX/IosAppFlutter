import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/cart_service.dart';
import 'cart_page.dart';
import 'home_tab.dart';
import 'login_page.dart';
import 'product_list_page.dart';
import 'profile_page.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex = widget.initialIndex;

  final _pages = const [
    HomeTab(),
    ProductListPage(),
    CartPage(),
    ProfilePage(),
  ];

  Future<void> _onDestinationSelected(int index) async {
    // "我的"页面需要登录
    if (index == 3) {
      final loggedIn = await ApiService.instance.isLoggedIn();
      if (!loggedIn) {
        if (!mounted) return;
        final shouldLogin = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('请先登录'),
            content: const Text('查看个人中心需要登录账号，是否立即登录？'),
            actions: [
              TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(false)),
              FilledButton(
                  child: const Text('去登录'),
                  onPressed: () => Navigator.of(context).pop(true)),
            ],
          ),
        );
        if (shouldLogin == true && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
        return;
      }
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: CartService.instance,
        builder: (context, _) {
          final cartCount = CartService.instance.totalCount;
          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: '首页',
              ),
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: '分类',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: '购物车',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          );
        },
      ),
    );
  }
}
