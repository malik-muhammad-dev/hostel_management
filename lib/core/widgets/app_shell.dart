import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hostel_management/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:hostel_management/features/expenses/presentation/screens/add_expanse_screen.dart';
import 'package:hostel_management/features/expenses/presentation/screens/expanses_screen.dart';
import 'package:hostel_management/features/fees/presentation/screens/fees_screen.dart';
import 'package:hostel_management/features/fees/presentation/screens/record_payment_screen.dart';
import 'package:hostel_management/features/reports/presentation/screens/fee_collection_report_screen.dart';
import 'package:hostel_management/features/reports/presentation/screens/financial_report_screen.dart';
import 'package:hostel_management/features/reports/presentation/screens/report_screen.dart';
import 'package:hostel_management/features/students/presentation/screens/add_student_screen.dart';
import 'package:hostel_management/features/students/presentation/screens/student_detail_screen.dart';
import 'package:hostel_management/features/students/presentation/screens/student_screen.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../app/theme/app_colors.dart';

import 'app_sidebar.dart';
import 'app_top_bar.dart';

class AppShellController extends GetxController {
  // ---------------------------------------------------------------------------
  // Main navigation
  // ---------------------------------------------------------------------------

  final selectedIndex = 0.obs;

  // ---------------------------------------------------------------------------
  // Content navigation stack
  //
  // The first page is the root page of the selected feature.
  // Additional pages are pushed on top of it.
  // ---------------------------------------------------------------------------

  final RxList<Widget> pageStack = <Widget>[].obs;

  @override
  void onInit() {
    super.onInit();

    _setInitialPage();

    // AppShellController is a singleton — it's only ever constructed
    // once, the first time AppShell builds. Without this, a second
    // person logging in later in the same app session (after the first
    // person logged out) would inherit whatever pageStack/selectedIndex
    // was last left behind, regardless of their own role — e.g. a Fee
    // Collector logging in after an Admin would still see the Admin's
    // Dashboard, since _setInitialPage() would never run again for them.
    // Re-running it every time the logged-in user actually changes (not
    // just once at startup) keeps each new login's starting page correct
    // for whoever just signed in.
    final authController = Get.find<AuthController>();
    ever(authController.currentUser, (_) {
      if (authController.isLoggedIn) {
        _setInitialPage();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Role-based sidebar visibility
  //
  // Fee Collector only ever sees the Fees section (index 2) — everything
  // else (Students, Expenses, Reports, and the Dashboard) is hidden.
  // Admin sees everything.
  // ---------------------------------------------------------------------------

  List<int> get visibleSidebarIndexes {
    final authController = Get.find<AuthController>();
    if (authController.isFeeCollector) {
      return const [2];
    }
    return const [0, 1, 2, 3, 4];
  }

  // ---------------------------------------------------------------------------
  // Initial page
  // ---------------------------------------------------------------------------

  void _setInitialPage() {
    final authController = Get.find<AuthController>();

    if (authController.isFeeCollector) {
      selectedIndex.value = 2;
      pageStack.assignAll([_pageForIndex(2)]);
      return;
    }

    pageStack.assignAll(const [DashboardScreen()]);
  }

  // ---------------------------------------------------------------------------
  // Current section title (used by the top bar)
  // ---------------------------------------------------------------------------

  String get currentSectionTitle {
    switch (selectedIndex.value) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Students';
      case 2:
        return 'Fees';
      case 3:
        return 'Expenses';
      case 4:
        return 'Reports';
      default:
        return 'Dashboard';
    }
  }

  // ---------------------------------------------------------------------------
  // Main sidebar navigation
  // ---------------------------------------------------------------------------

  void changePage(int index) {
    if (!visibleSidebarIndexes.contains(index)) {
      return;
    }

    selectedIndex.value = index;

    pageStack.assignAll([_pageForIndex(index)]);
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();

      case 1:
        return const StudentsScreen();

      case 2:
        return const FeesScreen();

      case 3:
        return const ExpensesScreen();

      case 4:
        return const ReportsScreen();

      default:
        return const DashboardScreen();
    }
  }

  // ---------------------------------------------------------------------------
  // Push a new page
  // ---------------------------------------------------------------------------

  void pushPage(Widget page) {
    pageStack.add(page);
  }

  // ---------------------------------------------------------------------------
  // Pop current page
  // ---------------------------------------------------------------------------

  bool popPage() {
    if (pageStack.length <= 1) {
      return false;
    }

    pageStack.removeLast();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Replace current page
  // ---------------------------------------------------------------------------

  void replacePage(Widget page) {
    if (pageStack.isEmpty) {
      pageStack.add(page);
      return;
    }

    pageStack[pageStack.length - 1] = page;
    pageStack.refresh();
  }

  // ---------------------------------------------------------------------------
  // Return to feature root
  // ---------------------------------------------------------------------------

  void popToRoot() {
    if (pageStack.length <= 1) {
      return;
    }

    final rootPage = pageStack.first;

    pageStack.assignAll([rootPage]);
  }

  // ---------------------------------------------------------------------------
  // Student navigation
  // ---------------------------------------------------------------------------

  void openStudentDetail() {
    pushPage(const StudentDetailScreen());
  }

  void openAddStudent() {
    pushPage(const AddStudentScreen());
  }

  // ---------------------------------------------------------------------------
  // Payment navigation
  // ---------------------------------------------------------------------------

  void openRecordPayment() {
    pushPage(const RecordPaymentScreen());
  }

  // ---------------------------------------------------------------------------
  // Expense navigation
  // ---------------------------------------------------------------------------

  void openAddExpense() {
    pushPage(const AddExpenseScreen());
  }

  // ---------------------------------------------------------------------------
  // Report navigation
  // ---------------------------------------------------------------------------

  void openFinancialReports() {
    pushPage(const FinancialReportsScreen());
  }

  void openFeeCollectionReport() {
    pushPage(const FeeCollectionReportScreen());
  }

  void backToFinancialReports() {
    popPage();
  }

  // ---------------------------------------------------------------------------
  // Current page
  // ---------------------------------------------------------------------------

  Widget get currentPage {
    if (pageStack.isEmpty) {
      return const DashboardScreen();
    }

    return pageStack.last;
  }
}

// =============================================================================
// App Shell
// =============================================================================

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppShellController>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Row(
        children: [
          // -------------------------------------------------------------------
          // Sidebar
          // -------------------------------------------------------------------
          Obx(
            () => AppSidebar(
              selectedIndex: controller.selectedIndex.value,
              onItemSelected: controller.changePage,
              visibleIndexes: controller.visibleSidebarIndexes,
            ),
          ),

          // -------------------------------------------------------------------
          // Main content
          // -------------------------------------------------------------------
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => AppTopBar(
                    sectionTitle: controller.currentSectionTitle,
                  ),
                ),

                Expanded(child: Obx(() => controller.currentPage)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}