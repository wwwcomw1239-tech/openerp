import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/drift/database.dart';

part 'database_provider.g.dart';

/// Database provider singleton
/// Provides the Drift database instance throughout the app
/// Uses keepAlive: true to keep the database connection alive
@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  return AppDatabase.instance;
}

/// Database async provider for initialization
@riverpod
Future<AppDatabase> databaseFuture(DatabaseFutureRef ref) async {
  return AppDatabase.instance;
}
