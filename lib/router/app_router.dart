import 'package:go_router/go_router.dart';

import 'package:laundrypro_uae/providers/auth_provider.dart';
import 'package:laundrypro_uae/views/accounting_screen.dart';
import 'package:laundrypro_uae/views/analytics_screen.dart';
import 'package:laundrypro_uae/views/app_shell.dart';
import 'package:laundrypro_uae/views/attendance_screen.dart';
import 'package:laundrypro_uae/views/branches_screen.dart';
import 'package:laundrypro_uae/views/business_screen.dart';
import 'package:laundrypro_uae/views/catalog_screen.dart';
import 'package:laundrypro_uae/views/challans_screen.dart';
import 'package:laundrypro_uae/views/channels_screen.dart';
import 'package:laundrypro_uae/views/customer_portal_screen.dart';
import 'package:laundrypro_uae/views/customers_screen.dart';
import 'package:laundrypro_uae/views/dashboard_screen.dart';
import 'package:laundrypro_uae/views/delivery_screen.dart';
import 'package:laundrypro_uae/views/employees_screen.dart';
import 'package:laundrypro_uae/views/expenses_screen.dart';
import 'package:laundrypro_uae/views/leave_screen.dart';
import 'package:laundrypro_uae/views/license_screen.dart';
import 'package:laundrypro_uae/views/localization_screen.dart';
import 'package:laundrypro_uae/views/login_screen.dart';
import 'package:laundrypro_uae/views/notifications_screen.dart';
import 'package:laundrypro_uae/views/payroll_screen.dart';
import 'package:laundrypro_uae/views/pending_invoices_screen.dart';
import 'package:laundrypro_uae/views/pos_screen.dart';
import 'package:laundrypro_uae/views/production_screen.dart';
import 'package:laundrypro_uae/views/purchasing_screen.dart';
import 'package:laundrypro_uae/views/reports_screen.dart';
import 'package:laundrypro_uae/views/setup_wizard_screen.dart';
import 'package:laundrypro_uae/views/settings_screen.dart';
import 'package:laundrypro_uae/views/splash_screen.dart';
import 'package:laundrypro_uae/views/storefront_screen.dart';
import 'package:laundrypro_uae/views/terminals_screen.dart';
import 'package:laundrypro_uae/views/sync_settings_screen.dart';
import 'package:laundrypro_uae/views/vendors_screen.dart';

class AppRouter {
  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        final path = state.uri.path;

        if (status == AuthStatus.unknown) {
          return path == '/splash' || path == '/setup' ? null : '/splash';
        }

        final isAuth = status == AuthStatus.authenticated;
        final isLoginRoute = path == '/login';
        final isSplash = path == '/splash';
        final isLicenseRoute = path == '/license';
        final isSetup = path == '/setup';

        if (!isAuth && !isLoginRoute && !isSplash && !isSetup) {
          return '/login';
        }

        if (isAuth && authProvider.licenseChecked && !authProvider.licenseActive && !authProvider.licenseBypass) {
          return isLicenseRoute ? null : '/license';
        }

        if (isAuth && (isLoginRoute || isSplash)) {
          if (!authProvider.licenseChecked) return null;
          if (!authProvider.licenseActive && !authProvider.licenseBypass) {
            return '/license';
          }
          return '/dashboard';
        }

        if (isAuth && isLicenseRoute && authProvider.licenseActive) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/license', builder: (context, state) => const LicenseScreen()),
        GoRoute(path: '/setup', builder: (context, state) => const SetupWizardScreen()),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
            GoRoute(path: '/pos', builder: (context, state) => const PosScreen()),
            GoRoute(path: '/customers', builder: (context, state) => const CustomersScreen()),
            GoRoute(path: '/vendors', builder: (context, state) => const VendorsScreen()),
            GoRoute(path: '/catalog', builder: (context, state) => const CatalogScreen()),
            GoRoute(path: '/pending', builder: (context, state) => const PendingInvoicesScreen()),
            GoRoute(path: '/production', builder: (context, state) => const ProductionScreen()),
            GoRoute(path: '/delivery', builder: (context, state) => const DeliveryScreen()),
            GoRoute(path: '/challans', builder: (context, state) => const ChallansScreen()),
            GoRoute(path: '/purchasing', builder: (context, state) => const PurchasingScreen()),
            GoRoute(path: '/hr/employees', builder: (context, state) => const EmployeesScreen()),
            GoRoute(path: '/hr/attendance', builder: (context, state) => const AttendanceScreen()),
            GoRoute(path: '/hr/leave', builder: (context, state) => const LeaveScreen()),
            GoRoute(path: '/hr/payroll', builder: (context, state) => const PayrollScreen()),
            GoRoute(path: '/expenses', builder: (context, state) => const ExpensesScreen()),
            GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
            GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
            GoRoute(path: '/sync', builder: (context, state) => const SyncSettingsScreen()),
            GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
            GoRoute(path: '/business', builder: (context, state) => const BusinessScreen()),
            GoRoute(path: '/admin/branches', builder: (context, state) => const BranchesScreen()),
            GoRoute(path: '/admin/terminals', builder: (context, state) => const TerminalsScreen()),
            GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen()),
            GoRoute(path: '/settings/channels', builder: (context, state) => const ChannelsScreen()),
            GoRoute(path: '/settings/accounting', builder: (context, state) => const AccountingScreen()),
            GoRoute(path: '/settings/localization', builder: (context, state) => const LocalizationScreen()),
            GoRoute(path: '/settings/storefront', builder: (context, state) => const StorefrontScreen()),
            GoRoute(path: '/customer', builder: (context, state) => const CustomerPortalScreen()),
          ],
        ),
      ],
    );
  }
}
