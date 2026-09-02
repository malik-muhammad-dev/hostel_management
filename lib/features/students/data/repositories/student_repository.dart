import '../datasources/student_data_source.dart';
import '../models/student_model.dart';

class StudentRepository {
  final StudentDataSource dataSource;

  StudentRepository(this.dataSource);

  Future<List<StudentModel>> getStudents() {
    return dataSource.getStudents();
  }

  Future<StudentModel?> getStudentById(String id) {
    return dataSource.getStudentById(id);
  }

  Future<void> addStudent(StudentModel student) {
    return dataSource.addStudent(student);
  }

  Future<void> updateStudent(StudentModel student) {
    return dataSource.updateStudent(student);
  }

  Future<void> deleteStudent(String id) {
    return dataSource.deleteStudent(id);
  }
}
