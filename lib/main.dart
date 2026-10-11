import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/models/history_entry.dart';
import 'core/services/history_service.dart';
import 'core/providers/shared_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileAds.instance.initialize();
  }

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryEntryStatusAdapter());
  Hive.registerAdapter(HistoryEntryAdapter());
  
  // Open the box via service
  final historyService = HistoryService();
  await historyService.init();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        historyServiceProvider.overrideWithValue(historyService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: ConvertixApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}
