import 'package:flutter/material.dart';

import 'screens/login_page.dart';
import 'screens/main_shell.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
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
            return const MainShell();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
