import 'package:hostel_management/features/students/data/datasources/student_service_datasource.dart' show StudentServiceDataSource;

import '../models/student_service_model.dart';

class MockStudentServiceDataSource implements StudentServiceDataSource {
  final List<StudentServiceModel> _services = [
    // -----------------------------------------------------------------------
    // Default Transport service for Ayesha
    // -----------------------------------------------------------------------
    const StudentServiceModel(
      id: 1,
      studentId: 1,
      name: 'Transport',
      description: 'College shuttle / hostel transport',
      monthlyAmount: 2000,
      isActive: true,
    ),
  ];

  @override
  Future<List<StudentServiceModel>> getServicesForStudent(
    int studentId,
  ) async {
    return List.unmodifiable(
      _services.where((service) => service.studentId == studentId),
    );
  }

  @override
  Future<void> addService(StudentServiceModel service) async {
    _services.add(service);
  }

  @override
  Future<void> updateService(StudentServiceModel service) async {
    final index = _services.indexWhere(
      (item) => item.id == service.id,
    );

    if (index == -1) {
      return;
    }

    _services[index] = service;
  }

  @override
  Future<void> deleteService(int serviceId) async {
    _services.removeWhere(
      (service) => service.id == serviceId,
    );
  }
}