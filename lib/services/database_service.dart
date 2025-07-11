import 'package:period_tracker/models/period_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._constructor();

  factory DatabaseService() {
    return _instance;
  }

  final String _databaseName = 'period_tracker.db';
  final int _databaseVersion = 1;
  final String _periodsTableName = 'periods';
  final String _periodsIdColumnName = 'id';
  final String _periodsStartDateColumnName = 'startDate';
  final String _periodsEndDateColumnName = 'endDate';

  DatabaseService._constructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await getDatabase();
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = p.join(databaseDirPath, _databaseName);

    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_periodsTableName (
        $_periodsIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
        $_periodsStartDateColumnName TEXT NOT NULL,
        $_periodsEndDateColumnName TEXT
      )
    ''');
  }

  Future<List<Period>> getAllPeriods() async {
    final db = await database;
    final rows = await db.query(_periodsTableName);
    return rows.map((row) => Period.fromMap(row)).toList();
  }

  Future<int> insertPeriod(Period period) async {
    final db = await database;
    return await db.insert(
      _periodsTableName,
      period.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deletePeriod(int id) async {
    final db = await database;
    return await db.delete(
      _periodsTableName,
      where: '$_periodsIdColumnName = ?',
      whereArgs: [id],
    );
  }

  // updatePeriod
  Future<int> updatePeriod(Period period) async {
    final db = await database;
    return await db.update(
      _periodsTableName,
      period.toMap(),
      where: '$_periodsIdColumnName = ?',
      whereArgs: [period.id],
    );
  }
}
