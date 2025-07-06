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
  final String _periodsStartDateColumnName = 'start_date';
  final String _periodsEndDateColumnName = 'end_date';

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

  Future<int> insertPeriod(String startDate, String? endDate) async {
    final db = await database;
    return await db.insert(_periodsTableName, {
      _periodsStartDateColumnName: startDate,
      _periodsEndDateColumnName: endDate,
    });
  }

  Future<List<Map<String, dynamic>>> getAllPeriods() async {
    final db = await database;
    return await db.query(_periodsTableName);
  }
}
