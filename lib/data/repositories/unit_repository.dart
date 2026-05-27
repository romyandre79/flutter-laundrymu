import 'package:kreatif_laundry_app/data/database/database_helper.dart';
import 'package:kreatif_laundry_app/data/models/unit.dart';

class UnitRepository {
  final DatabaseHelper _dbHelper;

  UnitRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Unit>> getUnits() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('units', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Unit.fromMap(maps[i]));
  }

  Future<int> insertUnit(Unit unit) async {
    final db = await _dbHelper.database;
    return await db.insert('units', unit.toMap());
  }

  Future<int> updateUnit(Unit unit) async {
    final db = await _dbHelper.database;
    return await db.update(
      'units',
      unit.toMap(),
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  Future<int> deleteUnit(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'units',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
