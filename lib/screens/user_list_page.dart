import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';

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

  Future<void> _changeRole(User user) async {
    if (user.id == null) return;
    final newRole = user.role == 'ADMIN' ? 'USER' : 'ADMIN';
    try {
      await ApiService.instance.updateUserRole(user.id!, newRole);
      await _reload();
    } catch (e) {
      _showError('修改失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<User>>(
          future: _futureUsers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('加载失败: ${snapshot.error}'));
            }

            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return const Center(child: Text('暂无用户'));
            }

            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final user = users[index];
                final isAdmin = user.isAdmin;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isAdmin ? Colors.red : Colors.blue,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(user.username ?? '未知'),
                  subtitle: Text(isAdmin ? '管理员' : '普通用户'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _changeRole(user),
                        child: Text(
                          isAdmin ? '设为普通用户' : '设为管理员',
                          style: TextStyle(
                            color: isAdmin ? Colors.orange : Colors.green,
                          ),
                        ),
                      ),
                      if (user.username != 'admin')
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('确认删除'),
                                content: Text('确定要删除用户 ${user.username} 吗？'),
                                actions: [
                                  TextButton(
                                    child: const Text('取消'),
                                    onPressed: () => Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: const Text('删除', style: TextStyle(color: Colors.red)),
                                    onPressed: () => Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                            ) ?? false;
                            if (confirm) {
                              await _deleteUser(user);
                            }
                          },
                        ),
                    ],
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