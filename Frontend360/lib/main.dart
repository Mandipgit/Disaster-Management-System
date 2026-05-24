import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/auth/auth_wrapper.dart';
import 'package:disaster360/services/session_service.dart';
import 'package:disaster360/services/deep_link_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 1. Await SessionService initialization completely
  final sessionService = SessionService();
  await sessionService.initialize();

  // 2. Initialize DeepLinkRouter ONLY after session is ready
  final router = DeepLinkRouter();
  router.initialize(); // Internally buffers until first frame

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: DisasterApp(router: router),
    ),
  );
}

class DisasterApp extends StatelessWidget {
  final DeepLinkRouter router;
  
  const DisasterApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: router.navigatorKey, // Injected for global routing
      title: 'Disaster360',
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
