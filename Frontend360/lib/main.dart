import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/auth/auth_wrapper.dart';
import 'package:disaster360/services/session_service.dart';
import 'package:disaster360/services/deep_link_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 1. Await SessionService initialization completely
  final sessionService = SessionService();
  await sessionService.initialize();

  // 2. Initialize DeepLinkRouter ONLY after session is ready
  final router = DeepLinkRouter();
  router.initialize(); // Internally buffers until first frame


   await Supabase.initialize(
    url: 'https://lavkbxvdjzyhznixpche.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxhdmtieHZkanp5aHpuaXhwY2hlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2MDcyODIsImV4cCI6MjA5NTE4MzI4Mn0.hxsjmII5VEL3EwJX1IA1cp2RfjUXb-motsaUo4bHTiI',
  );

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
      theme: ThemeData(
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
