import 'package:get/get.dart';

import '../../../fees/presentation/controllers/fee_controller.dart';
import '../../data/models/student_service_model.dart';
import '../../data/repositories/student_service_repository.dart';

class StudentServiceController extends GetxController {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final StudentServiceRepository repository;

  StudentServiceController(this.repository);

  // ---------------------------------------------------------------------------
  // Saved services for the currently selected student
  // ---------------------------------------------------------------------------

  final services = <StudentServiceModel>[].obs;

  // ---------------------------------------------------------------------------
  // Services being prepared while creating a NEW student
  //
  // A new student does not have an ID yet, so these stay as draft services
  // until StudentController generates the student ID.
  // ---------------------------------------------------------------------------

  final draftServices = <StudentServiceModel>[].obs;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final isLoading = false.obs;

  final selectedStudentId = Rxn<int>();

  // ---------------------------------------------------------------------------
  // Load services for an existing student
  // ---------------------------------------------------------------------------

  Future<void> loadServices(int studentId) async {
    try {
      isLoading.value = true;

      selectedStudentId.value = studentId;

      final result = await repository.getServicesForStudent(studentId);

      services.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Generate next service ID — LOCAL bookkeeping only.
  //
  // Only used for draftServices, so the Add/Edit Student form can
  // toggle/replace a draft entry (by id) before the student exists.
  // This id is discarded at save time (see saveDraftServices/addService,
  // which build a fresh model with id: null and let SQLite's own
  // AUTOINCREMENT assign the real one) — never pass a client-generated
  // id into an actual database insert.
  // ---------------------------------------------------------------------------

  int _nextServiceId() {
    final allIds = [
      ...services.map((service) => service.id ?? 0),
      ...draftServices.map((service) => service.id ?? 0),
    ];

    if (allIds.isEmpty) {
      return 1;
    }

    return allIds.reduce((a, b) => a > b ? a : b) + 1;
  }

  // ---------------------------------------------------------------------------
  // Add service to a NEW student
  // ---------------------------------------------------------------------------

  bool addDraftService({
    required String name,
    String? description,
    required double monthlyAmount,
  }) {
    if (name.trim().isEmpty || monthlyAmount <= 0) {
      return false;
    }

    final service = StudentServiceModel(
      id: _nextServiceId(),
      studentId: 0,
      name: name.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      monthlyAmount: monthlyAmount,
      isActive: true,
    );

    draftServices.add(service);

    return true;
  }

  // ---------------------------------------------------------------------------
  // Save draft services after a NEW student gets an ID
  // ---------------------------------------------------------------------------

 Future<bool> saveDraftServices(int studentId) async {
  if (studentId <= 0) {
    return false;
  }

  try {
    isLoading.value = true;

    for (final service in draftServices) {
      // Build a fresh model rather than copyWith — the draft's id was
      // only ever a local, in-memory bookkeeping value (used so the
      // Add/Edit Student form could toggle/replace a draft entry before
      // the student existed). It must NOT be carried into the database:
      // passing it straight through caused a real UNIQUE constraint
      // collision once real (SQLite-generated) student/service ids grew
      // large enough to overlap with these small client-guessed numbers.
      // Leaving `id` null here lets SQLite's own AUTOINCREMENT assign
      // the real one.
      final savedService = StudentServiceModel(
        studentId: studentId,
        name: service.name,
        description: service.description,
        monthlyAmount: service.monthlyAmount,
        isActive: service.isActive,
      );

      await repository.addService(savedService);
    }

    draftServices.clear();

    await loadServices(studentId);

    return true;
  } catch (e) {
    return false;
  } finally {
    isLoading.value = false;
  }
}
  // ---------------------------------------------------------------------------
  // Add service directly to an EXISTING student
  // ---------------------------------------------------------------------------

 Future<bool> addService({
  required int studentId,
  required String name,
  String? description,
  required double monthlyAmount,
}) async {
  if (studentId <= 0) {
    return false;
  }

  if (name.trim().isEmpty || monthlyAmount <= 0) {
    return false;
  }

  try {
    isLoading.value = true;

    // `id` intentionally left null — see the note in saveDraftServices()
    // above. SQLite assigns the real id on insert; reload from the
    // database afterward instead of appending this local copy, so
    // `services` always holds the actual persisted id.
    final service = StudentServiceModel(
      studentId: studentId,
      name: name.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      monthlyAmount: monthlyAmount,
      isActive: true,
    );

    await repository.addService(service);
    await loadServices(studentId);

    if (Get.isRegistered<FeeController>()) {
      await Get.find<FeeController>()
          .refreshServiceAmountsForStudent(studentId);
    }

    return true;
  } catch (e) {
    return false;
  } finally {
    isLoading.value = false;
  }
}
    // ---------------------------------------------------------------------------
  // Get active service
  // ---------------------------------------------------------------------------


Future<double> getActiveServiceAmountForStudent(
  int studentId,
) async {
  final studentServices =
      await repository.getServicesForStudent(studentId);

  return studentServices
      .where((service) => service.isActive)
      .fold<double>(
        0.0,
        (total, service) => total + service.monthlyAmount,
      );
}


  // ---------------------------------------------------------------------------
  // Update existing service
  // ---------------------------------------------------------------------------

  Future<bool> updateService(StudentServiceModel service) async {
  if (service.id == null) {
    return false;
  }

  try {
    isLoading.value = true;

    await repository.updateService(service);

    final index = services.indexWhere(
      (item) => item.id == service.id,
    );

    if (index != -1) {
      services[index] = service;
    }

    if (Get.isRegistered<FeeController>()) {
      await Get.find<FeeController>()
          .refreshServiceAmountsForStudent(
        service.studentId,
      );
    }

    return true;
  } catch (e) {
    return false;
  } finally {
    isLoading.value = false;
  }
}

  // ---------------------------------------------------------------------------
  // Enable / disable service
  // ---------------------------------------------------------------------------

  Future<bool> setServiceActive(
    StudentServiceModel service,
    bool isActive,
  ) async {
    final updatedService = service.copyWith(
      isActive: isActive,
    );

    return updateService(updatedService);
  }

  // ---------------------------------------------------------------------------
  // Delete existing service
  // ---------------------------------------------------------------------------

  Future<bool> deleteService(int serviceId) async {
  try {
    isLoading.value = true;

    final service = services.firstWhereOrNull(
      (item) => item.id == serviceId,
    );

    await repository.deleteService(serviceId);

    services.removeWhere(
      (item) => item.id == serviceId,
    );

    if (service != null &&
        Get.isRegistered<FeeController>()) {
      await Get.find<FeeController>()
          .refreshServiceAmountsForStudent(
        service.studentId,
      );
    }

    return true;
  } catch (e) {
    return false;
  } finally {
    isLoading.value = false;
  }
}
  // ---------------------------------------------------------------------------
  // Active saved services
  // ---------------------------------------------------------------------------

  List<StudentServiceModel> get activeServices {
    return services
        .where((service) => service.isActive)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Active draft services
  // ---------------------------------------------------------------------------

  List<StudentServiceModel> get activeDraftServices {
    return draftServices
        .where((service) => service.isActive)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Total active saved service amount
  // ---------------------------------------------------------------------------

  double get totalActiveServiceAmount {
    return activeServices.fold<double>(
      0.0,
      (total, service) => total + service.monthlyAmount,
    );
  }

  // ---------------------------------------------------------------------------
  // Total active draft service amount
  // ---------------------------------------------------------------------------

  double get totalDraftServiceAmount {
    return activeDraftServices.fold<double>(
      0.0,
      (total, service) => total + service.monthlyAmount,
    );
  }

  // ---------------------------------------------------------------------------
  // Clear everything
  // ---------------------------------------------------------------------------

  void clearServices() {
    selectedStudentId.value = null;
    services.clear();
    draftServices.clear();
  }

  // ---------------------------------------------------------------------------
  // Clear only draft services
  // ---------------------------------------------------------------------------

  void clearDraftServices() {
    draftServices.clear();
  }
}