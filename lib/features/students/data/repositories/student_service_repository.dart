import 'package:hostel_management/features/students/data/datasources/student_service_datasource.dart';

import '../models/student_service_model.dart';

class StudentServiceRepository {
  final StudentServiceDataSource dataSource;

  StudentServiceRepository(this.dataSource);

  Future<List<StudentServiceModel>> getServicesForStudent(
    int studentId,
  ) async {
    return dataSource.getServicesForStudent(studentId);
  }

  Future<void> addService(StudentServiceModel service) async {
    await dataSource.addService(service);
  }

  Future<void> updateService(StudentServiceModel service) async {
    await dataSource.updateService(service);
  }

  Future<void> deleteService(int serviceId) async {
    await dataSource.deleteService(serviceId);
  }
}