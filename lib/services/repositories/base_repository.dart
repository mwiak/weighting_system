import '../../database/database_helper.dart';

abstract class BaseRepository<T> {
  final DatabaseHelper _db = DatabaseHelper();
  final String tableName;

  BaseRepository(this.tableName);

  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);

  Future<int> insert(T item) async {
    final map = toMap(item);
    return await _db.insert(tableName, map);
  }

  Future<List<T>> getAll({
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final maps = await _db.query(
      tableName,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => fromMap(map)).toList();
  }

  Future<T?> getById(int id) async {
    final maps = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  Future<bool> update(T item, int id) async {
    final map = toMap(item);
    final count = await _db.update(
      tableName,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<bool> delete(int id) async {
    final count = await _db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<List<T>> search(String query, List<String> searchFields) async {
    final whereConditions = searchFields.map((field) => '$field LIKE ?').join(' OR ');
    final whereArgs = searchFields.map((field) => '%$query%').toList();
    
    final maps = await _db.query(
      tableName,
      where: whereConditions,
      whereArgs: whereArgs,
    );
    
    return maps.map((map) => fromMap(map)).toList();
  }

  Future<int> count({String? where, List<dynamic>? whereArgs}) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName ${where != null ? 'WHERE $where' : ''}',
      whereArgs,
    );
    return result.first['count'] as int;
  }
}