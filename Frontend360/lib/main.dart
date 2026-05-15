import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/auth/auth_wrapper.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const DisasterApp(),
    ),
  );
}

class DisasterApp extends StatelessWidget {
  const DisasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Disaster360',
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}
