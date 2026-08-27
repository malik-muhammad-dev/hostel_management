import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/student_model.dart';
import 'student_controller.dart';

class StudentFormController extends GetxController {
  final StudentModel? initialStudent;

  StudentFormController({
    this.initialStudent,
  });

  // ---------------------------------------------------------------------------
  // Mode
  // ---------------------------------------------------------------------------

  final editingStudent = Rxn<StudentModel>();

  bool get isEditMode => editingStudent.value != null;

  // ---------------------------------------------------------------------------
  // Personal
  // ---------------------------------------------------------------------------

  final nameController = TextEditingController();

  final studentIdController = TextEditingController();

  final cnicController = TextEditingController();

  final phoneController = TextEditingController();

  final emailController = TextEditingController();

  final dateOfBirthController = TextEditingController();

  final addressController = TextEditingController();

  final studentStatus = Rxn<String>();
    // ---------------------------------------------------------------------------
// Student photo
// ---------------------------------------------------------------------------

final selectedPhoto = Rxn<File>();

  // ---------------------------------------------------------------------------
  // Academic
  // ---------------------------------------------------------------------------

  final department = Rxn<String>();

  final program = Rxn<String>();

  final sessionController = TextEditingController();

  final semester = Rxn<String>();

  final admissionDateController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Hostel
  // ---------------------------------------------------------------------------

  final hostelBlockController = TextEditingController();

  final roomNumberController = TextEditingController();

  final bedNumberController = TextEditingController();

  final floorController = TextEditingController();

  final checkInDateController = TextEditingController();

  final expectedCheckOutController = TextEditingController();

  final hostelStatus = Rxn<String>();

  // ---------------------------------------------------------------------------
  // Guardian information
  // ---------------------------------------------------------------------------

  final guardianNameController = TextEditingController();

  final guardianCnicController = TextEditingController();

  final guardianPrimaryContactController = TextEditingController();

  final guardianAlternateContactController = TextEditingController();

  final guardianOccupationController = TextEditingController();

  final guardianAddressController = TextEditingController();

  final guardianRelationship = Rxn<String>();

  final gender = Rxn<String>();

  // ---------------------------------------------------------------------------
  // Fee
  // ---------------------------------------------------------------------------

  final packageStartDateController = TextEditingController();

  final monthlyFeeController = TextEditingController();

  final netMonthlyFeeController = TextEditingController();

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------

  final isSaving = false.obs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    if (initialStudent != null) {
      _populateStudent(initialStudent!);
    } else {
      _initializeNewStudent();
    }
  }

  // ---------------------------------------------------------------------------
  // New student
  // ---------------------------------------------------------------------------

  void _initializeNewStudent() {
    monthlyFeeController.text = '13000';
    netMonthlyFeeController.text = '13000';
  }

  // ---------------------------------------------------------------------------
  // Existing student
  // ---------------------------------------------------------------------------

  void _populateStudent(StudentModel student) {
    editingStudent.value = student;

    nameController.text = student.name;

    // Student ID is currently represented by rollNumber
    // in the StudentModel.
    studentIdController.text = student.rollNumber ?? '';

    cnicController.text = student.cnic ?? '';

    studentStatus.value = student.status;

    phoneController.text = student.phone ?? '';

    emailController.text = student.email ?? '';

    dateOfBirthController.text = student.dateOfBirth ?? '';

    addressController.text = student.address ?? '';

    gender.value = student.gender;

    hostelStatus.value = student.hostelStatus;

    department.value = student.department;

    program.value = student.program;

    sessionController.text = student.session ?? '';

    semester.value = student.semester;

    admissionDateController.text = student.admissionDate ?? '';

    hostelBlockController.text = student.hostelBlock ?? '';

    roomNumberController.text = student.roomNumber ?? '';

    bedNumberController.text = student.bedNumber ?? '';

    floorController.text = student.floor ?? '';

    checkInDateController.text = student.checkInDate ?? '';

    expectedCheckOutController.text =
        student.expectedCheckOut ?? '';

    packageStartDateController.text =
        student.packageStartDate ?? '';

    monthlyFeeController.text =
        student.monthlyFee?.toStringAsFixed(0) ?? '13000';

    netMonthlyFeeController.text =
        student.netMonthlyFee?.toStringAsFixed(0) ?? '13000';

    // -------------------------------------------------------------------------
    // Guardian
    // -------------------------------------------------------------------------

    guardianNameController.text =
        student.guardianName ?? '';

    guardianRelationship.value =
        student.guardianRelationship;

    guardianCnicController.text =
        student.guardianCnic ?? '';

    guardianPrimaryContactController.text =
        student.guardianPrimaryContact ?? '';

    guardianAlternateContactController.text =
        student.guardianAlternateContact ?? '';

    guardianOccupationController.text =
        student.guardianOccupation ?? '';

    guardianAddressController.text =
        student.guardianAddress ?? '';
  }

  // ---------------------------------------------------------------------------
  // Build model
  // ---------------------------------------------------------------------------

  StudentModel buildStudentModel() {
    final existing = editingStudent.value;

    return StudentModel(
      id: existing?.id,

      // -----------------------------------------------------------------------
      // Personal
      // -----------------------------------------------------------------------

      name: nameController.text.trim(),

      cnic: _nullable(
        cnicController.text,
      ),

      phone: _nullable(
        phoneController.text,
      ),

      email: _nullable(
        emailController.text,
      ),

      dateOfBirth: _nullable(
        dateOfBirthController.text,
      ),

      gender: gender.value ?? editingStudent.value?.gender,

      address: _nullable(
        addressController.text,
      ),

      // -----------------------------------------------------------------------
      // Guardian
      // -----------------------------------------------------------------------

      guardianName: _nullable(
        guardianNameController.text,
      ),

      guardianRelationship:
          guardianRelationship.value ?? editingStudent.value?.guardianRelationship,

      guardianCnic: _nullable(
        guardianCnicController.text,
      ),

      guardianPrimaryContact: _nullable(
        guardianPrimaryContactController.text,
      ),

      guardianAlternateContact: _nullable(
        guardianAlternateContactController.text,
      ),

      guardianOccupation: _nullable(
        guardianOccupationController.text,
      ),

      guardianAddress: _nullable(
        guardianAddressController.text,
      ),

      // -----------------------------------------------------------------------
      // Academic
      // -----------------------------------------------------------------------

      department: department.value ?? editingStudent.value?.department,

      program: program.value ?? editingStudent.value?.program,

      rollNumber: _nullable(
        studentIdController.text,
      ),

      session: _nullable(
        sessionController.text,
      ),

      semester: semester.value ?? editingStudent.value?.semester,

      admissionDate: _nullable(
        admissionDateController.text,
      ),

      // Falls back to the existing status if nothing was (re)selected —
      // this only matters for a status value outside the Active/Inactive
      // dropdown options (i.e. 'Archived'), which is intentionally not
      // selectable from this form. Without this fallback, editing an
      // archived student's other fields would silently clear their
      // status to null and unarchive them.
      status: studentStatus.value ?? editingStudent.value?.status,

      // -----------------------------------------------------------------------
      // Hostel
      // -----------------------------------------------------------------------

      hostelBlock: _nullable(
        hostelBlockController.text,
      ),

      roomNumber: _nullable(
        roomNumberController.text,
      ),

      bedNumber: _nullable(
        bedNumberController.text,
      ),

      floor: _nullable(
        floorController.text,
      ),

      checkInDate: _nullable(
        checkInDateController.text,
      ),

      expectedCheckOut: _nullable(
        expectedCheckOutController.text,
      ),

      hostelStatus: hostelStatus.value ?? editingStudent.value?.hostelStatus,

      // -----------------------------------------------------------------------
      // Financial
      // -----------------------------------------------------------------------

      packageStartDate: _nullable(
        packageStartDateController.text,
      ),

      monthlyFee: _parseAmount(
        monthlyFeeController.text,
      ),

      netMonthlyFee: _parseAmount(
        netMonthlyFeeController.text,
      ),

      // -----------------------------------------------------------------------
      // Ledger
      // -----------------------------------------------------------------------

      ledgerId: existing?.ledgerId,
    );
  }
 void setSelectedPhoto(File file) {
  selectedPhoto.value = file;
}

void clearSelectedPhoto() {
  selectedPhoto.value = null;
}
  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? validate() {
    // -------------------------------------------------------------------------
    // Personal information
    // -------------------------------------------------------------------------

    if (nameController.text.trim().isEmpty) {
      return 'Please enter the student name.';
    }

    if (studentIdController.text.trim().isEmpty) {
      return 'Please enter the student ID.';
    }

    // -------------------------------------------------------------------------
    // Roll number must be unique — a duplicate here previously risked
    // silently attaching services/edits to the wrong student (both share
    // the same displayed roll number, so staff can't tell them apart in
    // any list either).
    // -------------------------------------------------------------------------

    final rollNumber = studentIdController.text.trim().toLowerCase();

    final studentController = Get.find<StudentController>();

    final duplicate = studentController.students.any(
      (student) =>
          student.id != editingStudent.value?.id &&
          (student.rollNumber ?? '').trim().toLowerCase() == rollNumber,
    );

    if (duplicate) {
      return 'A student with this ID already exists. Please use a unique student ID.';
    }

    if (department.value == null || department.value!.trim().isEmpty) {
      return 'Please select a department.';
    }

    if (program.value == null || program.value!.trim().isEmpty) {
      return 'Please select a program.';
    }

    if (studentStatus.value == null || studentStatus.value!.trim().isEmpty) {
      return 'Please select a student status.';
    }

    if (hostelStatus.value == null || hostelStatus.value!.trim().isEmpty) {
      return 'Please select a hostel status.';
    }

    if (phoneController.text.trim().isEmpty) {
      return 'Please enter the phone number.';
    }

    // -------------------------------------------------------------------------
    // Email
    //
    // Only validate when provided because email is optional in the model.
    // -------------------------------------------------------------------------

    final email = emailController.text.trim();

    if (email.isNotEmpty && !_isValidEmail(email)) {
      return 'Please enter a valid email address.';
    }

    // -------------------------------------------------------------------------
    // Date of birth
    //
    // Optional field, so only validate when provided.
    // -------------------------------------------------------------------------

    final dateOfBirth = dateOfBirthController.text.trim();

    if (dateOfBirth.isNotEmpty) {
      if (_parseDate(dateOfBirth) == null) {
        return 'Please enter a valid date of birth.';
      }
    }

    // -------------------------------------------------------------------------
    // Admission date
    //
    // Optional in the current model, so only validate when provided.
    // -------------------------------------------------------------------------

    final admissionDate =
        admissionDateController.text.trim();

    if (admissionDate.isNotEmpty) {
      if (_parseDate(admissionDate) == null) {
        return 'Please enter a valid admission date.';
      }
    }

    // -------------------------------------------------------------------------
    // Package start date
    //
    // Optional in the current model.
    // -------------------------------------------------------------------------

  // -------------------------------------------------------------------------
// Package start date
// -------------------------------------------------------------------------

final packageStartDate =
    packageStartDateController.text.trim();

if (packageStartDate.isEmpty) {
  return 'Please select the package start date.';
}

if (_parseDate(packageStartDate) == null) {
  return 'Please enter a valid package start date.';
}

    // -------------------------------------------------------------------------
    // Hostel check-in / check-out
    //
    // Both are optional in the current model.
    //
    // If check-in exists:
    //   - it must be a valid date
    //
    // If check-out exists:
    //   - it must be a valid date
    //   - it must be AFTER check-in
    //
    // Therefore:
    //   Same day        -> invalid
    //   Before check-in -> invalid
    //   After check-in  -> valid
    // -------------------------------------------------------------------------

    final checkInText =
        checkInDateController.text.trim();

    final checkOutText =
        expectedCheckOutController.text.trim();

    DateTime? checkInDate;
    DateTime? checkOutDate;

    if (checkInText.isNotEmpty) {
      checkInDate = _parseDate(checkInText);

      if (checkInDate == null) {
        return 'Please enter a valid check-in date.';
      }
    }

    if (checkOutText.isNotEmpty) {
      checkOutDate = _parseDate(checkOutText);

      if (checkOutDate == null) {
        return 'Please enter a valid check-out date.';
      }
    }

    if (checkInDate != null &&
        checkOutDate != null) {
      if (!checkOutDate.isAfter(checkInDate)) {
        return 'Check-out date must be after the check-in date.';
      }
    }

    // -------------------------------------------------------------------------
    // Fee validation
    // -------------------------------------------------------------------------

    if (monthlyFeeController.text.trim().isEmpty) {
      return 'Please enter the monthly fee.';
    }

    final monthlyFee =
        _parseAmount(monthlyFeeController.text);

    final netMonthlyFee =
        _parseAmount(netMonthlyFeeController.text);

    if (monthlyFee == null || monthlyFee < 0) {
      return 'Please enter a valid monthly fee.';
    }

    if (netMonthlyFee == null || netMonthlyFee < 0) {
      return 'Please enter a valid net monthly fee.';
    }

    if (netMonthlyFee > monthlyFee) {
      return 'Net monthly fee cannot be greater than monthly fee.';
    }

    // -------------------------------------------------------------------------
    // Guardian validation
    // -------------------------------------------------------------------------

    if (guardianNameController.text.trim().isEmpty) {
      return 'Please enter the guardian name.';
    }

    if (guardianRelationship.value == null) {
      return 'Please select the guardian relationship.';
    }

    if (guardianPrimaryContactController.text
        .trim()
        .isEmpty) {
      return 'Please enter the guardian contact number.';
    }

    // -------------------------------------------------------------------------
    // Optional guardian alternate contact
    //
    // If supplied, make sure it isn't just whitespace.
    // -------------------------------------------------------------------------

    final alternateContact =
        guardianAlternateContactController.text.trim();

    if (alternateContact.isNotEmpty &&
        alternateContact.length < 7) {
      return 'Please enter a valid guardian alternate contact number.';
    }

    // -------------------------------------------------------------------------
    // CNIC
    //
    // Keep this intentionally lightweight for now.
    // We don't force a specific CNIC format until the UI/API contract
    // is confirmed.
    // -------------------------------------------------------------------------

    final cnic = cnicController.text.trim();

    if (cnic.isNotEmpty && cnic.length < 5) {
      return 'Please enter a valid CNIC.';
    }

    final guardianCnic =
        guardianCnicController.text.trim();

    if (guardianCnic.isNotEmpty &&
        guardianCnic.length < 5) {
      return 'Please enter a valid guardian CNIC.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Email validation
  // ---------------------------------------------------------------------------

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(value);
  }

  // ---------------------------------------------------------------------------
  // Date parsing
  //
  // Current implementation expects the date value to be parseable by
  // DateTime.tryParse(), which preserves the existing data representation.
  // ---------------------------------------------------------------------------

  DateTime? _parseDate(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String? _nullable(String value) {
    final result = value.trim();

    return result.isEmpty ? null : result;
  }

  double? _parseAmount(String value) {
    return double.tryParse(
      value.trim(),
    );
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void onClose() {
    nameController.dispose();

    studentIdController.dispose();

    cnicController.dispose();

    phoneController.dispose();

    emailController.dispose();

    dateOfBirthController.dispose();

    addressController.dispose();

    guardianNameController.dispose();

    guardianCnicController.dispose();

    guardianPrimaryContactController.dispose();

    guardianAlternateContactController.dispose();

    guardianOccupationController.dispose();

    guardianAddressController.dispose();

    sessionController.dispose();

    admissionDateController.dispose();

    hostelBlockController.dispose();

    roomNumberController.dispose();

    bedNumberController.dispose();

    floorController.dispose();

    checkInDateController.dispose();

    expectedCheckOutController.dispose();

    packageStartDateController.dispose();

    monthlyFeeController.dispose();

    netMonthlyFeeController.dispose();

    super.onClose();
  }
}