import 'package:get/get.dart';
import 'package:hostel_management/features/auth/data/datasource/auth_data_source.dart';
import 'package:hostel_management/features/auth/data/datasource/sqlite_auth_datasource.dart';

import 'package:hostel_management/features/auth/data/repositories/auth_repository.dart';
import 'package:hostel_management/features/auth/presentation/controllers/auth_controller.dart';
import 'package:hostel_management/features/expenses/data/datasources/expense_data_source.dart' show ExpenseDataSource;
import 'package:hostel_management/features/expenses/data/datasources/sqlite_expense_data_source.dart' show SqliteExpenseDataSource;
import 'package:hostel_management/features/expenses/data/repositories/expense_repository.dart' show ExpenseRepository;
import 'package:hostel_management/features/expenses/presentation/controllers/expense_controller.dart' show ExpenseController;
import 'package:hostel_management/features/reports/presentation/controllers/fee_collection_report_controller.dart';
import 'package:hostel_management/features/reports/presentation/controllers/report_controller.dart';
import 'package:hostel_management/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:hostel_management/features/students/data/datasources/sqlite_student_service_data_source.dart';
import 'package:hostel_management/features/students/data/datasources/sqlite_student_data_source.dart';
import 'package:hostel_management/features/students/data/datasources/sqlite_student_documnet_data_source.dart';
import 'package:hostel_management/features/students/data/datasources/student_service_datasource.dart' show StudentServiceDataSource;
import 'package:hostel_management/features/students/data/repositories/student_service_repository.dart' show StudentServiceRepository;
import 'package:hostel_management/features/students/presentation/controllers/student_service_controller.dart';

import 'package:hostel_management/features/students/data/datasources/student_document_data_source.dart';
import 'package:hostel_management/features/students/data/repositories/student_document_repository.dart';
import 'package:hostel_management/features/students/presentation/controllers/student_document_controller.dart';

import 'package:hostel_management/features/settings/data/datasource/app_settings_data_source.dart' show AppSettingsDataSource;
import 'package:hostel_management/features/settings/data/datasource/sqlite_app_settings_data_source.dart' show SqliteAppSettingsDataSource;
import 'package:hostel_management/features/settings/data/repositories/app_settings_repository.dart' show AppSettingsRepository;
import 'package:hostel_management/features/settings/presentation/controllers/app_settings_controller.dart' show AppSettingsController;

import 'package:hostel_management/features/receipts/data/datasources/receipt_data_source.dart' show ReceiptDataSource;
import 'package:hostel_management/features/receipts/data/datasources/sqlite_receipt_data_source.dart' show SqliteReceiptDataSource;
import 'package:hostel_management/features/receipts/data/repositories/receipt_repository.dart' show ReceiptRepository;
import 'package:hostel_management/features/receipts/presentation/controllers/receipt_controller.dart' show ReceiptController;

import '../../core/widgets/app_shell.dart';
import '../../features/fees/data/datasources/fee_data_source.dart';
import '../../features/fees/data/datasources/sqlite_fee_data_source.dart';
import '../../features/fees/data/repositories/fee_repository.dart';
import '../../features/fees/presentation/controllers/fee_controller.dart';
import '../../features/students/data/datasources/student_data_source.dart';
import '../../features/students/data/repositories/student_repository.dart';
import '../../features/students/presentation/controllers/student_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // -------------------------------------------------------------------------
    // App
    // -------------------------------------------------------------------------

    Get.lazyPut<AppShellController>(() => AppShellController(), fenix: true);

    // -------------------------------------------------------------------------
    // Auth
    // -------------------------------------------------------------------------

    Get.lazyPut<AuthDataSource>(() => SqliteAuthDataSource(), fenix: true);

    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find<AuthDataSource>()),
      fenix: true,
    );

    Get.lazyPut<AuthController>(
      () => AuthController(Get.find<AuthRepository>()),
      fenix: true,
    );

    // -------------------------------------------------------------------------
    // Student data layer
    // -------------------------------------------------------------------------

    Get.lazyPut<StudentDataSource>(() => SqliteStudentDataSource(), fenix: true);

    Get.lazyPut<StudentRepository>(
      () => StudentRepository(Get.find<StudentDataSource>()),
      fenix: true,
    );

// ---------------------------------------------------------------------------
// Student services
// ---------------------------------------------------------------------------

Get.lazyPut<StudentServiceDataSource>(
  () => SqliteStudentServiceDataSource(),
  fenix: true,
);

Get.lazyPut<StudentServiceRepository>(
  () => StudentServiceRepository(
    Get.find<StudentServiceDataSource>(),
  ),
  fenix: true,
);

Get.lazyPut<StudentServiceController>(
  () => StudentServiceController(
    Get.find<StudentServiceRepository>(),
  ),
  fenix: true,
);
    // ---------------------------------------------------------------------------
    // Student documents
    // ---------------------------------------------------------------------------

    Get.lazyPut<StudentDocumentDataSource>(
      () => SqliteStudentDocumentDataSource(),
      fenix: true,
    );

    Get.lazyPut<StudentDocumentRepository>(
      () => StudentDocumentRepository(
        Get.find<StudentDocumentDataSource>(),
      ),
      fenix: true,
    );

    Get.lazyPut<StudentDocumentController>(
      () => StudentDocumentController(
        Get.find<StudentDocumentRepository>(),
      ),
      fenix: true,
    );

    // -------------------------------------------------------------------------
    // Student controller
    // -------------------------------------------------------------------------

    Get.lazyPut<StudentController>(
      () => StudentController(Get.find<StudentRepository>()),
      fenix: true,
    );
    // ---------------------------------------------------------------------------
    // Fees
    // ---------------------------------------------------------------------------

    Get.lazyPut<FeeDataSource>(() => SqliteFeeDataSource(), fenix: true);

    Get.lazyPut<FeeRepository>(
      () => FeeRepository(Get.find<FeeDataSource>()),
      fenix: true,
    );

    Get.lazyPut<FeeController>(
      () => FeeController(Get.find<FeeRepository>()),
      fenix: true,
    );
    // ---------------------------------------------------------------------------
// Expenses
// ---------------------------------------------------------------------------

Get.lazyPut<ExpenseDataSource>(
  () => SqliteExpenseDataSource(),
  fenix: true,
);

Get.lazyPut<ExpenseRepository>(
  () => ExpenseRepository(
    Get.find<ExpenseDataSource>(),
  ),
  fenix: true,
);

Get.lazyPut<ExpenseController>(
  () => ExpenseController(
    Get.find<ExpenseRepository>(),
  ),
  fenix: true,
);
// ---------------------------------------------------------------------------
// Fee Collection Report
// ---------------------------------------------------------------------------

Get.lazyPut<FeeCollectionReportController>(
  () => FeeCollectionReportController(),
  fenix: true,
);
// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------

Get.lazyPut<ReportsController>(
  () => ReportsController(),
  fenix: true,
);

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

Get.lazyPut<DashboardController>(
  () => DashboardController(),
  fenix: true,
);

// ---------------------------------------------------------------------------
// App Settings (currently just Opening Balance)
// ---------------------------------------------------------------------------

Get.lazyPut<AppSettingsDataSource>(
  () => SqliteAppSettingsDataSource(),
  fenix: true,
);

Get.lazyPut<AppSettingsRepository>(
  () => AppSettingsRepository(Get.find<AppSettingsDataSource>()),
  fenix: true,
);

Get.lazyPut<AppSettingsController>(
  () => AppSettingsController(Get.find<AppSettingsRepository>()),
  fenix: true,
);

// ---------------------------------------------------------------------------
// Cash Receipts — money received outside of student fees. Its own
// independent data layer, same pattern as Expenses; DashboardController
// reads its total but nothing here reads back into Fees/Expenses.
// ---------------------------------------------------------------------------

Get.lazyPut<ReceiptDataSource>(
  () => SqliteReceiptDataSource(),
  fenix: true,
);

Get.lazyPut<ReceiptRepository>(
  () => ReceiptRepository(Get.find<ReceiptDataSource>()),
  fenix: true,
);

Get.lazyPut<ReceiptController>(
  () => ReceiptController(Get.find<ReceiptRepository>()),
  fenix: true,
);
  }

}