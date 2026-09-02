import '../models/student_model.dart';

abstract class StudentDataSource {
  Future<List<StudentModel>> getStudents();

  Future<StudentModel?> getStudentById(String id);

  Future<void> addStudent(StudentModel student);

  Future<void> updateStudent(StudentModel student);

  Future<void> deleteStudent(String id);
}