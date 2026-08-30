class StudentModel {
  final int? id;

  // ---------------------------------------------------------------------------
  // Personal information
  // ---------------------------------------------------------------------------

  final String name;
  // final String? fatherName;
  final String? cnic;
  final String? phone;
  final String? email;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? photoPath;

  // ---------------------------------------------------------------------------
  // Guardian information
  // ---------------------------------------------------------------------------

  final String? guardianName;
  final String? guardianRelationship;
  final String? guardianCnic;
  final String? guardianPrimaryContact;
  final String? guardianAlternateContact;
  final String? guardianOccupation;
  final String? guardianAddress;

  // ---------------------------------------------------------------------------
  // Academic information
  // ---------------------------------------------------------------------------

  final String? department;
  final String? program;
  final String? rollNumber;
  final String? session;
  final String? semester;
  final String? admissionDate;
  final String? status;

  // ---------------------------------------------------------------------------
  // Hostel information
  // ---------------------------------------------------------------------------

  final String? hostelBlock;
  final String? roomNumber;
  final String? bedNumber;
  final String? floor;
  final String? checkInDate;
  final String? expectedCheckOut;
  final String? hostelStatus;

  // ---------------------------------------------------------------------------
  // Financial / fee configuration
  // ---------------------------------------------------------------------------

  final String? packageStartDate;
  final double? monthlyFee;
  final double? netMonthlyFee;

  // ---------------------------------------------------------------------------
  // Financial / ledger relationship
  // ---------------------------------------------------------------------------

  final int? ledgerId;

  const StudentModel({
    this.id,

    // Personal
    required this.name,
    // /this.fatherName,
    this.cnic,
    this.phone,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.photoPath,

    // Guardian
    this.guardianName,
    this.guardianRelationship,
    this.guardianCnic,
    this.guardianPrimaryContact,
    this.guardianAlternateContact,
    this.guardianOccupation,
    this.guardianAddress,

    // Academic
    this.department,
    this.program,
    this.rollNumber,
    this.session,
    this.semester,
    this.admissionDate,
    this.status,

    // Hostel
    this.hostelBlock,
    this.roomNumber,
    this.bedNumber,
    this.floor,
    this.checkInDate,
    this.expectedCheckOut,
    this.hostelStatus,

    // Financial
    this.packageStartDate,
    this.monthlyFee,
    this.netMonthlyFee,

    // Ledger
    this.ledgerId,
  });

  // ---------------------------------------------------------------------------
  // Copy with
  // ---------------------------------------------------------------------------

  StudentModel copyWith({
    int? id,
    String? name,
    String? fatherName,
    String? cnic,
    String? phone,
    String? email,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? photoPath,

    // Guardian
    String? guardianName,
    String? guardianRelationship,
    String? guardianCnic,
    String? guardianPrimaryContact,
    String? guardianAlternateContact,
    String? guardianOccupation,
    String? guardianAddress,

    // Academic
    String? department,
    String? program,
    String? rollNumber,
    String? session,
    String? semester,
    String? admissionDate,
    String? status,

    // Hostel
    String? hostelBlock,
    String? roomNumber,
    String? bedNumber,
    String? floor,
    String? checkInDate,
    String? expectedCheckOut,
    String? hostelStatus,

    // Financial
    String? packageStartDate,
    double? monthlyFee,
    double? netMonthlyFee,

    // Ledger
    int? ledgerId,
  }) {
    return StudentModel(
      id: id ?? this.id,

      // Personal
      name: name ?? this.name,
      // fatherName: fatherName ?? this.fatherName,
      cnic: cnic ?? this.cnic,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      photoPath: photoPath ?? this.photoPath,

      // Guardian
      guardianName: guardianName ?? this.guardianName,
      guardianRelationship: guardianRelationship ?? this.guardianRelationship,
      guardianCnic: guardianCnic ?? this.guardianCnic,
      guardianPrimaryContact:
          guardianPrimaryContact ?? this.guardianPrimaryContact,
      guardianAlternateContact:
          guardianAlternateContact ?? this.guardianAlternateContact,
      guardianOccupation: guardianOccupation ?? this.guardianOccupation,
      guardianAddress: guardianAddress ?? this.guardianAddress,

      // Academic
      department: department ?? this.department,
      program: program ?? this.program,
      rollNumber: rollNumber ?? this.rollNumber,
      session: session ?? this.session,
      semester: semester ?? this.semester,
      admissionDate: admissionDate ?? this.admissionDate,
      status: status ?? this.status,

      // Hostel
      hostelBlock: hostelBlock ?? this.hostelBlock,
      roomNumber: roomNumber ?? this.roomNumber,
      bedNumber: bedNumber ?? this.bedNumber,
      floor: floor ?? this.floor,
      checkInDate: checkInDate ?? this.checkInDate,
      expectedCheckOut: expectedCheckOut ?? this.expectedCheckOut,
      hostelStatus: hostelStatus ?? this.hostelStatus,

      // Financial
      packageStartDate: packageStartDate ?? this.packageStartDate,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      netMonthlyFee: netMonthlyFee ?? this.netMonthlyFee,

      // Ledger
      ledgerId: ledgerId ?? this.ledgerId,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialization — for SqliteStudentDataSource
  // ---------------------------------------------------------------------------

  Map<String, Object?> toMap() {
    return {
      'id': id,

      // Personal
      'name': name,
      'cnic': cnic,
      'phone': phone,
      'email': email,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'address': address,
      'photo_path': photoPath,

      // Guardian
      'guardian_name': guardianName,
      'guardian_relationship': guardianRelationship,
      'guardian_cnic': guardianCnic,
      'guardian_primary_contact': guardianPrimaryContact,
      'guardian_alternate_contact': guardianAlternateContact,
      'guardian_occupation': guardianOccupation,
      'guardian_address': guardianAddress,

      // Academic
      'department': department,
      'program': program,
      'roll_number': rollNumber,
      'session': session,
      'semester': semester,
      'admission_date': admissionDate,
      'status': status,

      // Hostel
      'hostel_block': hostelBlock,
      'room_number': roomNumber,
      'bed_number': bedNumber,
      'floor': floor,
      'check_in_date': checkInDate,
      'expected_check_out': expectedCheckOut,
      'hostel_status': hostelStatus,

      // Financial
      'package_start_date': packageStartDate,
      'monthly_fee': monthlyFee,
      'net_monthly_fee': netMonthlyFee,

      // Ledger
      'ledger_id': ledgerId,
    };
  }

  factory StudentModel.fromMap(Map<String, Object?> map) {
    return StudentModel(
      id: map['id'] as int?,

      // Personal
      name: map['name'] as String,
      cnic: map['cnic'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
      gender: map['gender'] as String?,
      address: map['address'] as String?,
      photoPath: map['photo_path'] as String?,

      // Guardian
      guardianName: map['guardian_name'] as String?,
      guardianRelationship: map['guardian_relationship'] as String?,
      guardianCnic: map['guardian_cnic'] as String?,
      guardianPrimaryContact: map['guardian_primary_contact'] as String?,
      guardianAlternateContact:
          map['guardian_alternate_contact'] as String?,
      guardianOccupation: map['guardian_occupation'] as String?,
      guardianAddress: map['guardian_address'] as String?,

      // Academic
      department: map['department'] as String?,
      program: map['program'] as String?,
      rollNumber: map['roll_number'] as String?,
      session: map['session'] as String?,
      semester: map['semester'] as String?,
      admissionDate: map['admission_date'] as String?,
      status: map['status'] as String?,

      // Hostel
      hostelBlock: map['hostel_block'] as String?,
      roomNumber: map['room_number'] as String?,
      bedNumber: map['bed_number'] as String?,
      floor: map['floor'] as String?,
      checkInDate: map['check_in_date'] as String?,
      expectedCheckOut: map['expected_check_out'] as String?,
      hostelStatus: map['hostel_status'] as String?,

      // Financial
      packageStartDate: map['package_start_date'] as String?,
      monthlyFee: (map['monthly_fee'] as num?)?.toDouble(),
      netMonthlyFee: (map['net_monthly_fee'] as num?)?.toDouble(),

      // Ledger
      ledgerId: map['ledger_id'] as int?,
    );
  }
}

// =============================================================================
// CONSTRAINED FIELD OPTIONS
//
// Department, Program, and Semester are stored as plain strings (schema
// stays flexible if the list changes later), but the values must come
// from a fixed list — both the Add/Edit Student form and the Students
// filter bar import these same constants, so a value typed in the form
// is *always* filterable, and a filter option always matches real data.
// Never let either side define its own separate list again.
// =============================================================================

// Corrected directly from ONIMS's own admissions poster (the client's
// source of truth — the earlier onims.edu.pk/admissions-page version
// was missing the whole 2-year diploma tier and grouped departments
// wrong). Per the client: DPT, BS-MLT, LHV, CMW and every 2-year
// diploma program all sit under one "Allied Health Sciences"
// department; Nursing, Pharmacy and Computing stay separate.
const List<String> kStudentDepartments = [
  'Allied Health Sciences',
  'Nursing & Midwifery',
  'Pharmacy',
  'Computing',
];

const List<String> kStudentPrograms = [
  // Degree programs
  'DPT (Doctor of Physiotherapy)',
  'Pharm-D (Doctor of Pharmacy)',
  'BS-MLT',
  'BSN (Nursing)',
  'Post-RN',
  'BSCS',
  'BSIT',

  // 2-year diploma, after Matric — females only
  'LHV (Lady Health Visitor)',
  'CMW (Community Midwifery)',

  // 2-year diploma, after Matric (F.Sc equivalent)
  'Operation Theater Technology',
  'Radiography & Imaging Technology',
  'Medical Lab Technology (Diploma)',
  'Dispensing Technology',
  'Anesthesia Technician',
  'Pharmacy Technician',
  'Physiotherapy Technology',
];

const List<String> kStudentSemesters = [
  '1st',
  '2nd',
  '3rd',
  '4th',
  '5th',
  '6th',
  '7th',
  '8th',
];