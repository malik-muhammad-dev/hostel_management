import '../models/student_service_model.dart';

abstract class StudentServiceDataSource {
  Future<List<StudentServiceModel>> getServicesForStudent(
    int studentId,
  );

  Future<void> addService(StudentServiceModel service);

  Future<void> updateService(StudentServiceModel service);

  Future<void> deleteService(int serviceId);
}