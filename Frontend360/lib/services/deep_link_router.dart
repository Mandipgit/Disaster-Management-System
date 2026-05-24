import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:disaster360/services/session_service.dart';
import 'package:disaster360/citizen/emergency_report_screen.dart';
import 'package:disaster360/auth/auth_wrapper.dart';

class DeepLinkRouter {
  static final DeepLinkRouter _instance = DeepLinkRouter._internal();
  factory DeepLinkRouter() => _instance;
  DeepLinkRouter._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription? _sessionSubscription;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  bool _isNavigated = false;
  final List<Uri> _eventBuffer = [];
  bool _isAppReady = false;

  void initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isAppReady = true;
      _processBuffer();
    });

    _initDeepLinks();

    // Listen to session changes to redirect if logout happens during emergency mode
    _sessionSubscription = SessionService().sessionStream.listen((user) {
      if (user == null && navigatorKey.currentContext != null) {
        // If user logged out while we are in emergency screen, we drop out
        Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    });
  }

  Future<void> _initDeepLinks() async {
    // Check initial link if app was in cold state (terminated)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      // Ignored
    }

    // Attach a listener to the stream
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      // Handle error
    });
  }

  void _handleDeepLink(Uri uri) {
    _eventBuffer.add(uri);
    if (_isAppReady) {
      _processBuffer();
    }
  }

  void _processBuffer() {
    if (_eventBuffer.isEmpty) return;

    // Grab the first event, clear the rest to avoid duplicate fires in same frame
    final uri = _eventBuffer.first;
    _eventBuffer.clear();

    if (uri.toString().contains('emergency')) {
      _routeToEmergency();
    }
  }

  void _routeToEmergency() {
    if (_isNavigated) return; // Navigation Lock
    _isNavigated = true;
    _tryPushRoute();
  }

  void _tryPushRoute() {
    if (navigatorKey.currentState != null) {
      final sessionService = SessionService();
      if (sessionService.currentUser != null) {
        // We have a session, push the emergency screen directly
        navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (_) => const EmergencyReportScreen())
        ).then((_) {
          // Unlock when returning
          _isNavigated = false;
        });
      } else {
        // No session, redirect to login
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        ).then((_) {
          _isNavigated = false;
        });
      }
    } else {
      // Retry after a short delay if navigator is not yet mounted
      Future.delayed(const Duration(milliseconds: 200), _tryPushRoute);
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _sessionSubscription?.cancel();
  }
}
