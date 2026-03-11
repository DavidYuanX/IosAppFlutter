import 'package:flutter/material.dart';

import 'screens/login_page.dart';
import 'screens/user_list_page.dart';
import 'services/api_service.dart';

void main() {
  runApp(const CrudApp());
}

class CrudApp extends StatelessWidget {
  const CrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: FutureBuilder<bool>(
        future: ApiService.instance.isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final loggedIn = snapshot.data ?? false;
          if (loggedIn) {
            return const UserListPage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
