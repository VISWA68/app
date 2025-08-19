import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/memory_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 2, // Increment version to trigger migration
      onCreate: (db, version) async {
        // Table for memories with new schema
        await db.execute('''
          CREATE TABLE memories(
            id TEXT PRIMARY KEY,
            author TEXT NOT NULL,
            text TEXT NOT NULL,
            photoUrls TEXT, -- JSON array of photo URLs
            timestamp TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        // Table for user settings (e.g., character choice)
        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration from version 1 to 2
          await _migrateToVersion2(db);
        }
      },
    );
  }

  Future<void> _migrateToVersion2(Database db) async {
    // Check if the old table exists and has the old schema
    try {
      // First, let's check what columns exist
      final tableInfo = await db.rawQuery("PRAGMA table_info(memories)");
      final columnNames = tableInfo
          .map((row) => row['name'] as String)
          .toList();

      if (columnNames.contains('photoUrl') &&
          !columnNames.contains('photoUrls')) {
        // Old schema detected, need to migrate
        print('Migrating memories table from old schema...');

        // Create new table with correct schema
        await db.execute('''
          CREATE TABLE memories_new(
            id TEXT PRIMARY KEY,
            author TEXT NOT NULL,
            text TEXT NOT NULL,
            photoUrls TEXT, -- JSON array of photo URLs
            timestamp TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        // Copy data from old table to new table, converting photoUrl to photoUrls
        final oldMemories = await db.query('memories');
        for (final memory in oldMemories) {
          final newMemory = Map<String, dynamic>.from(memory);

          // Convert single photoUrl to photoUrls array
          if (memory['photoUrl'] != null) {
            newMemory['photoUrls'] = jsonEncode([memory['photoUrl']]);
          } else {
            newMemory['photoUrls'] = null;
          }
          newMemory.remove('photoUrl'); // Remove old column

          // Ensure timestamp is string format
          if (newMemory['timestamp'] is int) {
            newMemory['timestamp'] = DateTime.fromMillisecondsSinceEpoch(
              newMemory['timestamp'] as int,
            ).toIso8601String();
          }

          await db.insert('memories_new', newMemory);
        }

        // Drop old table and rename new table
        await db.execute('DROP TABLE memories');
        await db.execute('ALTER TABLE memories_new RENAME TO memories');

        print('Migration completed successfully');
      } else if (!columnNames.contains('photoUrls')) {
        // Table exists but doesn't have photoUrls column, add missing columns
        await db.execute('ALTER TABLE memories ADD COLUMN photoUrls TEXT');
        await db.execute('ALTER TABLE memories ADD COLUMN latitude REAL');
        await db.execute('ALTER TABLE memories ADD COLUMN longitude REAL');
        await db.execute(
          'ALTER TABLE memories ADD COLUMN created_at TEXT DEFAULT CURRENT_TIMESTAMP',
        );
      }
    } catch (e) {
      print('Migration error: $e');
      // If migration fails, recreate the table
      await db.execute('DROP TABLE IF EXISTS memories');
      await db.execute('''
        CREATE TABLE memories(
          id TEXT PRIMARY KEY,
          author TEXT NOT NULL,
          text TEXT NOT NULL,
          photoUrls TEXT,
          timestamp TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
  }

  // New methods for character selection
  Future<void> saveCharacterChoice(String character) async {
    final db = await database;
    await db.insert('settings', {
      'key': 'character',
      'value': character,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getCharacterChoice() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['character'],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'];
    }
    return null;
  }

  // Insert a new memory
  Future<void> insertMemory(Memory memory) async {
    final db = await database;

    final memoryData = memory.toJson();
    // Convert photoUrls list to JSON string for storage
    if (memory.photoUrls != null) {
      memoryData['photoUrls'] = jsonEncode(memory.photoUrls);
    }

    await db.insert(
      'memories',
      memoryData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all memories
  Future<List<Memory>> getMemories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);

      // Parse photoUrls JSON string back to list
      if (map['photoUrls'] != null && map['photoUrls'] is String) {
        try {
          map['photoUrls'] = jsonDecode(map['photoUrls'] as String);
        } catch (e) {
          debugPrint('Error parsing photoUrls: $e');
          map['photoUrls'] = null;
        }
      }

      return Memory.fromJson(map);
    });
  }

  // Get memories by author
  Future<List<Memory>> getMemoriesByAuthor(String author) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'author = ?',
      whereArgs: [author],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);

      if (map['photoUrls'] != null && map['photoUrls'] is String) {
        try {
          map['photoUrls'] = jsonDecode(map['photoUrls'] as String);
        } catch (e) {
          debugPrint('Error parsing photoUrls: $e');
          map['photoUrls'] = null;
        }
      }

      return Memory.fromJson(map);
    });
  }

  // Get memories from a specific date range
  Future<List<Memory>> getMemoriesInDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);

      if (map['photoUrls'] != null && map['photoUrls'] is String) {
        try {
          map['photoUrls'] = jsonDecode(map['photoUrls'] as String);
        } catch (e) {
          debugPrint('Error parsing photoUrls: $e');
          map['photoUrls'] = null;
        }
      }

      return Memory.fromJson(map);
    });
  }

  // Update a memory
  Future<void> updateMemory(Memory memory) async {
    final db = await database;

    final memoryData = memory.toJson();
    if (memory.photoUrls != null) {
      memoryData['photoUrls'] = jsonEncode(memory.photoUrls);
    }

    await db.update(
      'memories',
      memoryData,
      where: 'id = ?',
      whereArgs: [memory.id],
    );
  }

  // Delete a memory
  Future<void> deleteMemory(String memoryId) async {
    final db = await database;
    await db.delete('memories', where: 'id = ?', whereArgs: [memoryId]);
  }

  // Get memory by ID
  Future<Memory?> getMemoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final map = Map<String, dynamic>.from(maps.first);

      if (map['photoUrls'] != null && map['photoUrls'] is String) {
        try {
          map['photoUrls'] = jsonDecode(map['photoUrls'] as String);
        } catch (e) {
          debugPrint('Error parsing photoUrls: $e');
          map['photoUrls'] = null;
        }
      }

      return Memory.fromJson(map);
    }

    return null;
  }

  // Get memories count
  Future<int> getMemoriesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM memories');
    return result.first['count'] as int;
  }

  // Get memories count by author
  Future<int> getMemoriesCountByAuthor(String author) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM memories WHERE author = ?',
      [author],
    );
    return result.first['count'] as int;
  }

  // Search memories by text
  Future<List<Memory>> searchMemories(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'text LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);

      if (map['photoUrls'] != null && map['photoUrls'] is String) {
        try {
          map['photoUrls'] = jsonDecode(map['photoUrls'] as String);
        } catch (e) {
          debugPrint('Error parsing photoUrls: $e');
          map['photoUrls'] = null;
        }
      }

      return Memory.fromJson(map);
    });
  }

  // Clear all memories (for testing or reset)
  Future<void> clearAllMemories() async {
    final db = await database;
    await db.delete('memories');
  }
}
