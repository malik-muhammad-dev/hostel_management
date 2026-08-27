import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/student_repository.dart';

class StudentController extends GetxController {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final StudentRepository repository;

  StudentController(this.repository);


  // ---------------------------------------------------------------------------
  // Student data
  // ---------------------------------------------------------------------------

  final students = <StudentModel>[].obs;
  final filteredStudents = <StudentModel>[].obs;

  // ---------------------------------------------------------------------------
  // Active (non-Archived) students, independent of the Students screen's
  // own search/filter state.
  //
  // Other features (Fees, Reports, ...) that need "every real student"
  // should use this — not `filteredStudents`, which also carries
  // whatever search text / department / status dropdown the Students
  // screen currently has selected, and not `students`, which still
  // includes Archived (soft-deleted) students.
  // ---------------------------------------------------------------------------

  List<StudentModel> get activeStudents =>
      students.where((student) => student.status != 'Archived').toList();

  // ---------------------------------------------------------------------------
  // Selected student
  // ---------------------------------------------------------------------------

  final selectedStudent = Rxn<StudentModel>();

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  final searchQuery = ''.obs;

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  final selectedDepartment = 'All Departments'.obs;
  final selectedProgram = 'All Programs'.obs;
  final selectedSemester = 'All Semesters'.obs;
  final selectedStatus = 'All Status'.obs;

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------

  final isLoading = false.obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    loadStudents();
  }

  // ---------------------------------------------------------------------------
  // Load students
  // ---------------------------------------------------------------------------

  Future<void> loadStudents() async {
    try {
      isLoading.value = true;

      final result = await repository.getStudents();

      students.assignAll(result);

      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Add student
  // ---------------------------------------------------------------------------
  int _nextStudentId() {
    if (students.isEmpty) {
      return 1;
    }

    return students
            .map((student) => student.id ?? 0)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<StudentModel?> addStudent(StudentModel student) async {
    try {
      isLoading.value = true;

      final studentWithId = student.copyWith(id: _nextStudentId());

      await repository.addStudent(studentWithId);

      await loadStudents();

      return studentWithId;
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] addStudent failed: $e');
      debugPrint('[DEBUG] stackTrace: $stackTrace');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
  

  // ---------------------------------------------------------------------------
  // Update student
  // ---------------------------------------------------------------------------

  Future<bool> updateStudent(StudentModel updatedStudent) async {
    if (updatedStudent.id == null) {
      return false;
    }

    try {
      isLoading.value = true;

      await repository.updateStudent(updatedStudent);

      final index = students.indexWhere(
        (student) => student.id == updatedStudent.id,
      );

      if (index != -1) {
        students[index] = updatedStudent;
      }

      if (selectedStudent.value?.id == updatedStudent.id) {
        selectedStudent.value = updatedStudent;
      }

      _applyFilters();

      return true;
    } finally {
      isLoading.value = false;
    }
  }
  // ---------------------------------------------------------------------------
  // Archive student (soft delete)
  //
  // We never hard-delete a student — the `students` table cascades onto
  // fee_transactions/fee_payments/student_services in SQLite (ON DELETE
  // CASCADE), so a real delete would permanently wipe a student's entire
  // financial history along with them. Instead we mark the student as
  // 'Archived' and hide them from the default list, keeping all of their
  // records intact for future reference/audit.
  // ---------------------------------------------------------------------------

  Future<bool> archiveStudent(int id) async {
    try {
      isLoading.value = true;

      final student = students.firstWhereOrNull((s) => s.id == id);
      if (student == null) return false;

      final archived = student.copyWith(status: 'Archived');
      await repository.updateStudent(archived);
      await loadStudents();

      return true;
    } catch (e) {
      debugPrint('[DEBUG] archiveStudent failed: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }


  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  void searchStudents(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------
 

  void setDepartment(String value) {
    selectedDepartment.value = value;
    _applyFilters();
  }

  void setProgram(String value) {
    selectedProgram.value = value;
    _applyFilters();
  }

  void setSemester(String value) {
    selectedSemester.value = value;
    _applyFilters();
  }

  void setStatus(String value) {
    selectedStatus.value = value;
    _applyFilters();
  }

  // ---------------------------------------------------------------------------
  // Apply search + filters
  // ---------------------------------------------------------------------------

  void _applyFilters() {
    final query = searchQuery.value.trim().toLowerCase();

    final result = students.where((student) {
      final matchesSearch =
          query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          (student.rollNumber?.toLowerCase().contains(query) ?? false) ||
          (student.cnic?.toLowerCase().contains(query) ?? false) ||
          (student.phone?.toLowerCase().contains(query) ?? false);

      final matchesDepartment =
          selectedDepartment.value == 'All Departments' ||
          student.department == selectedDepartment.value;

      final matchesProgram =
          selectedProgram.value == 'All Programs' ||
          student.program == selectedProgram.value;

      final matchesSemester =
          selectedSemester.value == 'All Semesters' ||
          student.semester == selectedSemester.value;

      final matchesStatus =
          selectedStatus.value == 'All Status' ||
          student.status == selectedStatus.value;

      // Archived (soft-deleted) students are hidden from every view
      // unless the user explicitly filters for them.
      final isArchived = student.status == 'Archived';
      final showArchived = selectedStatus.value == 'Archived';

      return matchesSearch &&
          matchesDepartment &&
          matchesProgram &&
          matchesSemester &&
          matchesStatus &&
          (!isArchived || showArchived);
    }).toList();

    filteredStudents.assignAll(result);

    // Reset to the first page whenever the filtered set changes — this
    // lives here (the single place filteredStudents is ever written to)
    // so it's impossible for a future filter/search addition to forget
    // it and leave the user stranded on an out-of-range page showing an
    // empty list.
    currentPage.value = 1;
  }

  // ---------------------------------------------------------------------------
  // Pagination
  //
  // `paginatedStudents` is what the table actually renders — always a
  // safe, in-range slice of `filteredStudents`, even if `currentPage`
  // somehow ends up stale relative to the current filtered count (e.g. a
  // student is archived while on the last page). The slicing is
  // defensive on purpose: it must never throw a RangeError.
  // ---------------------------------------------------------------------------

  final currentPage = 1.obs;

  static const int pageSize = AppConstants.defaultPageSize;

  int get totalPages {
    if (filteredStudents.isEmpty) return 1;
    return (filteredStudents.length / pageSize).ceil();
  }

  List<StudentModel> get paginatedStudents {
    final total = filteredStudents.length;
    if (total == 0) return const [];

    final page = currentPage.value.clamp(1, totalPages);

    final start = ((page - 1) * pageSize).clamp(0, total);
    final end = (start + pageSize).clamp(0, total);

    return filteredStudents.sublist(start, end);
  }

  void nextPage() {
    if (currentPage.value < totalPages) {
      currentPage.value++;
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  // ---------------------------------------------------------------------------
  // Student selection
  // ---------------------------------------------------------------------------

  void selectStudent(StudentModel student) {
    selectedStudent.value = student;
  }

  void clearSelectedStudent() {
    selectedStudent.value = null;
  }

  // ---------------------------------------------------------------------------
  // Reset filters
  // ---------------------------------------------------------------------------

  void resetFilters() {
    searchQuery.value = '';

    selectedDepartment.value = 'All Departments';
    selectedProgram.value = 'All Programs';
    selectedSemester.value = 'All Semesters';
    selectedStatus.value = 'All Status';

    filteredStudents.assignAll(students);
  }
}