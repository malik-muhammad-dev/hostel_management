import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/student_service_model.dart';
import 'student_service_datasource.dart';

class SqliteStudentServiceDataSource implements StudentServiceDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  @override
  Future<List<StudentServiceModel>> getServicesForStudent(
    String studentId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'student_services',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'id ASC',
    );
    return rows.map(StudentServiceModel.fromMap).toList();
  }

  @override
  Future<void> addService(StudentServiceModel service) async {
    final db = await _db;
    await db.insert(
      'student_services',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateService(StudentServiceModel service) async {
    if (service.id == null) return;

    final db = await _db;
    await db.update(
      'student_services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  @override
  Future<void> deleteService(String serviceId) async {
    final db = await _db;
    await db.delete(
      'student_services',
      where: 'id = ?',
      whereArgs: [serviceId],
    );
  }
}