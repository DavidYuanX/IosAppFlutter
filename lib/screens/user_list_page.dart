import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'user_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late Future<List<User>> _futureUsers;

  @override
  void initState() {
    super.initState();
    _futureUsers = ApiService.instance.fetchUsers();
  }

  Future<void> _reload() async {
    setState(() {
      _futureUsers = ApiService.instance.fetchUsers();
    });
  }

  Future<void> _logout() async {
    await ApiService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _deleteUser(User user) async {
    if (user.id == null) return;
    try {
      await ApiService.instance.deleteUser(user.id!);
      await _reload();
    } catch (e) {
      _showError('删除失败: $e');
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('错误'),
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

  void _openAddUser() async {
    final result = await Navigator.of(context).push<User?>(
      MaterialPageRoute(builder: (_) => const UserDetailPage()),
    );
    if (result != null && mounted) {
      _reload();
    }
  }

  void _openEditUser(User user) async {
    final result = await Navigator.of(context).push<User?>(
      MaterialPageRoute(builder: (_) => UserDetailPage(user: user)),
    );
    if (result != null && mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '退出',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddUser,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<User>>(
          future: _futureUsers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('加载失败: ${snapshot.error}'),
                    ),
                  ),
                ],
              );
            }

            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 200,
                    child: Center(child: Text('暂无用户')),
                  ),
                ],
              );
            }

            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final user = users[index];
                return Dismissible(
                  key: ValueKey(user.id ?? user.email),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除用户 ${user.name} 吗？'),
                            actions: [
                              TextButton(
                                child: const Text('取消'),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                              TextButton(
                                child: const Text('删除'),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (confirm) {
                      await _deleteUser(user);
                    }
                    return false;
                  },
                  child: ListTile(
                    title: Text(user.name),
                    subtitle: Text('${user.email}\n${user.phone ?? ''}'),
                    isThreeLine: true,
                    onTap: () => _openEditUser(user),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
