import 'package:hostel_management/features/students/data/models/student_document%20model.dart';

import '../datasources/student_document_data_source.dart';

class StudentDocumentRepository {
  final StudentDocumentDataSource dataSource;

  StudentDocumentRepository(this.dataSource);

  Future<List<StudentDocumentModel>> getDocumentsForStudent(
    String studentId,
  ) {
    return dataSource.getDocumentsForStudent(studentId);
  }

  Future<void> addDocument(StudentDocumentModel document) {
    return dataSource.addDocument(document);
  }

  Future<void> updateDocument(StudentDocumentModel document) {
    return dataSource.updateDocument(document);
  }

  Future<void> deleteDocument(String documentId) {
    return dataSource.deleteDocument(documentId);
  }
}