import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.hasSupabaseAuth) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabasePublishableKey,
      );
    } catch (error, stackTrace) {
      debugPrint('Supabase startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Render the app before initializing optional Android services. Some OEMs
  // throw platform exceptions while notification channels or launch-details
  // are being initialized; those errors must never prevent Hani Maak from
  // opening.
  runApp(const ProviderScope(child: HaniMaakApp()));

  unawaited(_initializeOptionalPlatformServices());
}

Future<void> _initializeOptionalPlatformServices() async {
  try {
    await HaniNotificationService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('Notification startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
