import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pixmind.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // تحليلات AI للصور
    await db.execute('''
      CREATE TABLE media_analysis (
        id TEXT PRIMARY KEY,
        ai_caption TEXT,
        extracted_text TEXT,
        sentiment TEXT,
        credibility_score REAL,
        labels TEXT,
        analyzed_at INTEGER
      )
    ''');

    // تجميع الوجوه
    await db.execute('''
      CREATE TABLE person_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        cover_asset_id TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE person_assets (
        person_id TEXT,
        asset_id TEXT,
        PRIMARY KEY (person_id, asset_id)
      )
    ''');

    // الملفات المحمية
    await db.execute('''
      CREATE TABLE secure_files (
        id TEXT PRIMARY KEY,
        asset_id TEXT NOT NULL,
        added_at INTEGER
      )
    ''');

    // الصور المكررة
    await db.execute('''
      CREATE TABLE duplicates (
        asset_id TEXT,
        group_id TEXT,
        phash TEXT,
        PRIMARY KEY (asset_id)
      )
    ''');
  }

  // Media Analysis CRUD
  Future<void> saveAnalysis(String assetId, Map<String, dynamic> data) async {
    final database = await db;
    await database.insert(
      'media_analysis',
      {'id': assetId, ...data, 'analyzed_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getAnalysis(String assetId) async {
    final database = await db;
    final results = await database.query(
      'media_analysis',
      where: 'id = ?',
      whereArgs: [assetId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Secure Files CRUD
  Future<void> addSecureFile(String assetId) async {
    final database = await db;
    await database.insert('secure_files', {
      'id': assetId,
      'asset_id': assetId,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeSecureFile(String assetId) async {
    final database = await db;
    await database.delete('secure_files', where: 'asset_id = ?', whereArgs: [assetId]);
  }

  Future<List<String>> getSecureFileIds() async {
    final database = await db;
    final results = await database.query('secure_files');
    return results.map((r) => r['asset_id'] as String).toList();
  }

  // Person Groups CRUD
  Future<void> savePersonGroup(String id, String name, String? coverId) async {
    final database = await db;
    await database.insert('person_groups', {
      'id': id,
      'name': name,
      'cover_asset_id': coverId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> addAssetToPerson(String personId, String assetId) async {
    final database = await db;
    await database.insert('person_assets', {
      'person_id': personId,
      'asset_id': assetId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> getPersonGroups() async {
    final database = await db;
    return database.query('person_groups');
  }

  Future<List<String>> getPersonAssetIds(String personId) async {
    final database = await db;
    final results = await database.query(
      'person_assets',
      where: 'person_id = ?',
      whereArgs: [personId],
    );
    return results.map((r) => r['asset_id'] as String).toList();
  }
}
