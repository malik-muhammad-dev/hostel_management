import 'package:get/get.dart';
import 'package:hostel_management/features/students/data/models/student_document%20model.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/student_document_repository.dart';

class StudentDocumentController extends GetxController {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final StudentDocumentRepository repository;

  StudentDocumentController(this.repository);

  // ---------------------------------------------------------------------------
  // Saved documents for the currently selected (existing) student
  // ---------------------------------------------------------------------------

  final documents = <StudentDocumentModel>[].obs;

  // ---------------------------------------------------------------------------
  // Documents being prepared while creating a NEW student
  //
  // A new student does not have an ID yet, so these stay as draft
  // documents until StudentController generates the student ID.
  // ---------------------------------------------------------------------------

  final draftDocuments = <StudentDocumentModel>[].obs;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final isLoading = false.obs;

  final selectedStudentId = Rxn<String>();

  // ---------------------------------------------------------------------------
  // Load documents for an existing student
  // ---------------------------------------------------------------------------

  Future<void> loadDocuments(String studentId) async {
    try {
      isLoading.value = true;

      selectedStudentId.value = studentId;

      final result = await repository.getDocumentsForStudent(studentId);

      documents.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Attach/replace a document while creating a NEW student
  //
  // Named (required) documents like CNIC use `title` as their identity —
  // attaching CNIC again replaces the existing draft entry rather than
  // duplicating it. Custom documents ("Add Other Document") always add a
  // new entry since they don't have a fixed title to key off of.
  //
  // `id` is intentionally left null here. Drafts are only ever matched
  // by `title` (never by id — see removeDraftDocumentByTitle,
  // draftDocumentByTitle), so there's no need to invent one before this
  // document is actually persisted. The real id (a client-generated
  // UUID — the `id` column has no AUTOINCREMENT to fall back on) is
  // assigned in saveDraftDocuments/setDocument right before the row is
  // actually inserted. `studentId` is likewise a placeholder here (the
  // new student doesn't have a real id yet) and gets overwritten with
  // the real one in saveDraftDocuments.
  // ---------------------------------------------------------------------------

  bool setDraftDocument({
    required String title,
    required String fileName,
    String? filePath,
    bool isRequired = false,
    bool replaceByTitle = false,
  }) {
    if (title.trim().isEmpty || fileName.trim().isEmpty) {
      return false;
    }

    final document = StudentDocumentModel(
      studentId: '',
      title: title.trim(),
      fileName: fileName.trim(),
      filePath: filePath,
      isRequired: isRequired,
    );

    if (replaceByTitle) {
      final index = draftDocuments.indexWhere(
        (item) => item.title == title.trim(),
      );

      if (index != -1) {
        draftDocuments[index] = document;
        return true;
      }
    }

    draftDocuments.add(document);
    return true;
  }

  void removeDraftDocumentByTitle(String title) {
    draftDocuments.removeWhere((item) => item.title == title);
  }

  void removeDraftDocumentAt(int index) {
    if (index < 0 || index >= draftDocuments.length) return;
    draftDocuments.removeAt(index);
  }

  // ---------------------------------------------------------------------------
  // Save draft documents after a NEW student gets an ID
  // ---------------------------------------------------------------------------

  Future<bool> saveDraftDocuments(String studentId) async {
    if (studentId.trim().isEmpty) {
      return false;
    }

    try {
      isLoading.value = true;

      for (final document in draftDocuments) {
        final savedDocument = document.copyWith(
          id: const Uuid().v4(),
          studentId: studentId,
        );
        await repository.addDocument(savedDocument);
      }

      draftDocuments.clear();

      await loadDocuments(studentId);

      return true;
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[DEBUG] saveDraftDocuments failed: $e');
      print('[DEBUG] stackTrace: $stackTrace');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Attach/replace a document directly on an EXISTING student
  // ---------------------------------------------------------------------------

  Future<bool> setDocument({
    required String studentId,
    required String title,
    required String fileName,
    String? filePath,
    bool isRequired = false,
  }) async {
    if (studentId.trim().isEmpty) return false;
    if (title.trim().isEmpty || fileName.trim().isEmpty) return false;

    try {
      isLoading.value = true;

      final existing = documents.firstWhereOrNull(
        (item) => item.title == title.trim(),
      );

      if (existing != null) {
        final updated = existing.copyWith(
          fileName: fileName.trim(),
          filePath: filePath,
        );
        await repository.updateDocument(updated);

        final index = documents.indexWhere((item) => item.id == updated.id);
        if (index != -1) documents[index] = updated;
      } else {
        // `id` is a freshly generated UUID — the `id` column has no
        // AUTOINCREMENT to assign one on insert. Reload from the
        // database afterward rather than trusting this local copy, so
        // `documents` always holds the actual persisted row (needed for
        // later update/delete calls to target the right row).
        final document = StudentDocumentModel(
          id: const Uuid().v4(),
          studentId: studentId,
          title: title.trim(),
          fileName: fileName.trim(),
          filePath: filePath,
          isRequired: isRequired,
        );

        await repository.addDocument(document);
        await loadDocuments(studentId);
      }

      return true;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Remove an existing document
  // ---------------------------------------------------------------------------

  Future<bool> deleteDocument(String documentId) async {
    try {
      isLoading.value = true;

      await repository.deleteDocument(documentId);
      documents.removeWhere((item) => item.id == documentId);

      return true;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Lookup helpers
  // ---------------------------------------------------------------------------

  StudentDocumentModel? documentByTitle(String title) {
    return documents.firstWhereOrNull((item) => item.title == title);
  }

  StudentDocumentModel? draftDocumentByTitle(String title) {
    return draftDocuments.firstWhereOrNull((item) => item.title == title);
  }

  List<StudentDocumentModel> get otherDocuments {
    const namedTitles = {
      'CNIC',
      'Admission Form',
      'College / Student Card',
      'Medical Certificate',
    };
    return documents
        .where((item) => !namedTitles.contains(item.title))
        .toList();
  }

  List<StudentDocumentModel> get otherDraftDocuments {
    const namedTitles = {
      'CNIC',
      'Admission Form',
      'College / Student Card',
      'Medical Certificate',
    };
    return draftDocuments
        .where((item) => !namedTitles.contains(item.title))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Clear everything
  // ---------------------------------------------------------------------------

  void clearDocuments() {
    selectedStudentId.value = null;
    documents.clear();
    draftDocuments.clear();
  }

  void clearDraftDocuments() {
    draftDocuments.clear();
  }
}