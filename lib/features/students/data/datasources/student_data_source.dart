import '../models/student_model.dart';

abstract class StudentDataSource {
  Future<List<StudentModel>> getStudents();

  Future<StudentModel?> getStudentById(int id);

  Future<void> addStudent(StudentModel student);

  Future<void> updateStudent(StudentModel student);

  Future<void> deleteStudent(int id);
}
