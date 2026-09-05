import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:laundrypro_uae/peripherals/features/dashboard/screens/dashboard_shell_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const DashboardShellScreen();
      },
    ),
  ],
);
