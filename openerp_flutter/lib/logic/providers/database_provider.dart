import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/drift/app_database.dart';

/// Database provider singleton
/// Provides the Drift database instance throughout the app
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Database async provider for initialization
final databaseFutureProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.instance;
});
