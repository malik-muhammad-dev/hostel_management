import 'package:hostel_management/features/students/data/models/student_document%20model.dart';

import 'student_document_data_source.dart';

class MockStudentDocumentDataSource implements StudentDocumentDataSource {
  final List<StudentDocumentModel> _documents = [];

  @override
  Future<List<StudentDocumentModel>> getDocumentsForStudent(
    String studentId,
  ) async {
    return _documents
        .where((document) => document.studentId == studentId)
        .toList();
  }

  @override
  Future<void> addDocument(StudentDocumentModel document) async {
    _documents.add(document);
  }

  @override
  Future<void> updateDocument(StudentDocumentModel document) async {
    final index = _documents.indexWhere((item) => item.id == document.id);
    if (index == -1) return;
    _documents[index] = document;
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    _documents.removeWhere((item) => item.id == documentId);
  }
}