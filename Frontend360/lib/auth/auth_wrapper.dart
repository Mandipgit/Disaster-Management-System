import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/citizen/citizen_home_screen.dart';
import 'package:disaster360/admin/admin_home_dashboard.dart';
import 'package:disaster360/rescue/rescue_home_screen.dart';
import 'package:disaster360/auth/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated || auth.user == null) {
      return const LoginScreen();
    }

    // Role-based routing
    if (auth.user!.role.toLowerCase() == 'admin') {
      return const AdminHomeScreen();
    } else if (auth.user!.role.toLowerCase() == 'rescue') {
      return const RescueHomeScreen();
    } else {
      return const CitizenHomeScreen();
    }
  }
}