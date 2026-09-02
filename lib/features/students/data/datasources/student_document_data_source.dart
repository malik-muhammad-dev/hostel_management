
import 'package:hostel_management/features/students/data/models/student_document%20model.dart';

abstract class StudentDocumentDataSource {
  Future<List<StudentDocumentModel>> getDocumentsForStudent(String studentId);

  Future<void> addDocument(StudentDocumentModel document);

  Future<void> updateDocument(StudentDocumentModel document);

  Future<void> deleteDocument(String documentId);
}