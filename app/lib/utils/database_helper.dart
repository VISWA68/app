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
      version: 1,
      onCreate: (db, version) async {
        // Table for memories
        await db.execute('''
          CREATE TABLE memories(
            id TEXT PRIMARY KEY,
            author TEXT,
            text TEXT,
            photoUrl TEXT,
            timestamp INTEGER
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
    );
  }

  // New methods for character selection
  Future<void> saveCharacterChoice(String character) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'character', 'value': character},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  // Existing methods for memories...
  Future<void> insertMemory(Memory memory) async {
    final db = await database;
    await db.insert('memories', memory.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Memory>> getMemories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('memories');
    return List.generate(maps.length, (i) {
      return Memory.fromMap(maps[i]);
    });
  }
}