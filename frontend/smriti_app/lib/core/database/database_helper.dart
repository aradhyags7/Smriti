// SMRITI - Database Helper Singleton
// Owner: Aradhya (AI + Database + Sync)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'database_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;
    try {
      if (kIsWeb) {
        path = inMemoryDatabasePath;
      } else {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, DatabaseSchema.dbName);
      }
    } catch (_) {
      path = inMemoryDatabasePath;
    }

    return await openDatabase(
      path,
      version: DatabaseSchema.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(DatabaseSchema.createPatientsTable);
    await db.execute(DatabaseSchema.createGameAttemptsTable);
    await db.execute(DatabaseSchema.createDailyCheckinsTable);
    await db.execute(DatabaseSchema.createRemindersTable);
    await db.execute(DatabaseSchema.createOfflineEventsTable);

    for (final idx in DatabaseSchema.createIndexes) {
      await db.execute(idx);
    }
  }

  static void setMockDatabase(Database? mockDb) {
    _database = mockDb;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
