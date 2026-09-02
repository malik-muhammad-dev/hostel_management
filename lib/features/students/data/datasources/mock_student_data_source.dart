import '../models/student_model.dart';
import 'student_data_source.dart';

class MockStudentDataSource implements StudentDataSource {
  final List<StudentModel> _students = [
    const StudentModel(
      id: 'mock-student-1',

      // -----------------------------------------------------------------------
      // Personal
      // -----------------------------------------------------------------------
      name: 'Ayesha Khan',
      // fatherName: 'Muhammad Khan',
      cnic: '35202-1234567-8',
      phone: '0300-1234567',
      email: 'ayesha.khan@example.com',
      dateOfBirth: '2004-05-12',
      gender: 'Female',
      address: 'House 24, Street 5, Mianwali',

      // -----------------------------------------------------------------------
      // Academic
      // -----------------------------------------------------------------------
      department: 'Nursing',
      program: 'BS Nursing',
      rollNumber: 'BSN-001',
      session: '2023-2027',
      semester: '4th',
      admissionDate: '2023-09-01',
      status: 'Active',

      // -----------------------------------------------------------------------
      // Guardian
      // -----------------------------------------------------------------------
      guardianName: 'Muhammad Khan',
      guardianRelationship: 'Father',
      guardianCnic: '35202-9876543-1',
      guardianPrimaryContact: '0300-1112233',
      guardianAlternateContact: '0321-4455667',
      guardianOccupation: 'Business',
      guardianAddress: 'House 24, Street 5, Mianwali',

      // -----------------------------------------------------------------------
      // Hostel
      // -----------------------------------------------------------------------
      hostelBlock: 'Block A',
      roomNumber: 'A-204',
      bedNumber: 'Bed 2',
      floor: '2nd Floor',
      checkInDate: '2023-09-05',
      expectedCheckOut: '2027-06-30',
      hostelStatus: 'Active',

      // -----------------------------------------------------------------------
      // Fee configuration
      // -----------------------------------------------------------------------
      packageStartDate: '2023-09-05',
      monthlyFee: 13000,
      netMonthlyFee: 13000,

      // -----------------------------------------------------------------------
      // Ledger
      // -----------------------------------------------------------------------
      ledgerId: 1,
    ),

    const StudentModel(
      id: 'mock-student-2',

      // -----------------------------------------------------------------------
      // Personal
      // -----------------------------------------------------------------------
      name: 'Sara Ahmed',
      // fatherName: 'Ahmed Khan',
      cnic: '35202-2345678-9',
      phone: '0312-7654321',
      email: 'sara.ahmed@example.com',
      dateOfBirth: '2005-02-18',
      gender: 'Female',
      address: 'Street 8, Model Town, Mianwali',

      // -----------------------------------------------------------------------
      // Academic
      // -----------------------------------------------------------------------
      department: 'Nursing',
      program: 'BS Nursing',
      rollNumber: 'BSN-002',
      session: '2024-2028',
      semester: '3rd',
      admissionDate: '2024-09-01',
      status: 'Active',

      // -----------------------------------------------------------------------
      // Guardian
      // -----------------------------------------------------------------------
      guardianName: 'Ahmed Khan',
      guardianRelationship: 'Father',
      guardianCnic: '35202-8765432-4',
      guardianPrimaryContact: '0312-1112233',
      guardianAlternateContact: '0333-7788990',
      guardianOccupation: 'Government Employee',
      guardianAddress: 'Street 8, Model Town, Mianwali',

      // -----------------------------------------------------------------------
      // Hostel
      // -----------------------------------------------------------------------
      hostelBlock: 'Block A',
      roomNumber: 'A-205',
      bedNumber: 'Bed 1',
      floor: '2nd Floor',
      checkInDate: '2024-09-05',
      expectedCheckOut: '2028-06-30',
      hostelStatus: 'Active',

      // -----------------------------------------------------------------------
      // Fee configuration
      // -----------------------------------------------------------------------
      packageStartDate: '2024-09-05',
      monthlyFee: 13000,
      netMonthlyFee: 12500,

      // -----------------------------------------------------------------------
      // Ledger
      // -----------------------------------------------------------------------
      ledgerId: 2,
    ),

    const StudentModel(
      id: 'mock-student-3',

      // -----------------------------------------------------------------------
      // Personal
      // -----------------------------------------------------------------------
      name: 'Fatima Ali',
      // fatherName: 'Imran Ali',
      cnic: '35202-3456789-0',
      phone: '0301-4567890',
      email: 'fatima.ali@example.com',
      dateOfBirth: '2005-08-25',
      gender: 'Female',
      address: 'College Road, Mianwali',

      // -----------------------------------------------------------------------
      // Academic
      // -----------------------------------------------------------------------
      department: 'Medical',
      program: 'BS',
      rollNumber: 'BS-003',
      session: '2024-2028',
      semester: '2nd',
      admissionDate: '2024-09-01',
      status: 'Active',

      // -----------------------------------------------------------------------
      // Guardian
      // -----------------------------------------------------------------------
      guardianName: 'Imran Ali',
      guardianRelationship: 'Father',
      guardianCnic: '35202-7654321-5',
      guardianPrimaryContact: '0301-2223344',
      guardianAlternateContact: '0345-6677889',
      guardianOccupation: 'Shop Owner',
      guardianAddress: 'College Road, Mianwali',

      // -----------------------------------------------------------------------
      // Hostel
      // -----------------------------------------------------------------------
      hostelBlock: 'Block B',
      roomNumber: 'B-102',
      bedNumber: 'Bed 3',
      floor: '1st Floor',
      checkInDate: '2024-09-05',
      expectedCheckOut: '2028-06-30',
      hostelStatus: 'Active',

      // -----------------------------------------------------------------------
      // Fee configuration
      // -----------------------------------------------------------------------
      packageStartDate: '2024-09-05',
      monthlyFee: 13000,
      netMonthlyFee: 13000,

      // -----------------------------------------------------------------------
      // Ledger
      // -----------------------------------------------------------------------
      ledgerId: 3,
    ),

    const StudentModel(
      id: 'mock-student-4',

      // -----------------------------------------------------------------------
      // Personal
      // -----------------------------------------------------------------------
      name: 'Maryam Khan',
      // fatherName: 'Khalid Khan',
      cnic: '35202-4567890-1',
      phone: '0304-9876543',
      email: 'maryam.khan@example.com',
      dateOfBirth: '2003-11-10',
      gender: 'Female',
      address: 'Block C, Mianwali',

      // -----------------------------------------------------------------------
      // Academic
      // -----------------------------------------------------------------------
      department: 'Pharmacy',
      program: 'DPT',
      rollNumber: 'DPT-004',
      session: '2022-2026',
      semester: '5th',
      admissionDate: '2022-09-01',
      status: 'Inactive',

      // -----------------------------------------------------------------------
      // Guardian
      // -----------------------------------------------------------------------
      guardianName: 'Khalid Khan',
      guardianRelationship: 'Father',
      guardianCnic: '35202-6543210-6',
      guardianPrimaryContact: '0304-3334455',
      guardianAlternateContact: '0322-9988776',
      guardianOccupation: 'Farmer',
      guardianAddress: 'Block C, Mianwali',

      // -----------------------------------------------------------------------
      // Hostel
      // -----------------------------------------------------------------------
      hostelBlock: 'Block C',
      roomNumber: 'C-301',
      bedNumber: 'Bed 2',
      floor: '3rd Floor',
      checkInDate: '2022-09-05',
      expectedCheckOut: '2026-06-30',
      hostelStatus: 'Inactive',

      // -----------------------------------------------------------------------
      // Fee configuration
      // -----------------------------------------------------------------------
      packageStartDate: '2022-09-05',
      monthlyFee: 13000,
      netMonthlyFee: 11000,

      // -----------------------------------------------------------------------
      // Ledger
      // -----------------------------------------------------------------------
      ledgerId: 4,
    ),
  ];

  @override
  Future<List<StudentModel>> getStudents() async {
    return List.unmodifiable(_students);
  }

  @override
  Future<StudentModel?> getStudentById(String id) async {
    for (final student in _students) {
      if (student.id == id) {
        return student;
      }
    }

    return null;
  }

  @override
  Future<void> addStudent(StudentModel student) async {
    _students.add(student);
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    final index = _students.indexWhere((item) => item.id == student.id);

    if (index == -1) {
      return;
    }

    _students[index] = student;
  }

  @override
  Future<void> deleteStudent(String id) async {
    _students.removeWhere((student) => student.id == id);
  }
}