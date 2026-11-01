import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/widgets/empty_state.dart';

class AppDataTableColumn {
  final String label;
  final bool numeric;
  final Widget Function(dynamic row)? cellBuilder;
  final String? key;

  const AppDataTableColumn({
    required this.label,
    this.numeric = false,
    this.cellBuilder,
    this.key,
  });
}

class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.data,
    required this.isLoading,
    this.emptyMessage = 'No records found',
    this.onRowTap,
  });

  final List<AppDataTableColumn> columns;
  final List<dynamic> data;
  final bool isLoading;
  final String emptyMessage;
  final void Function(dynamic row)? onRowTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTokens.brandTeal));
    }

    if (data.isEmpty) {
      return EmptyState(
        icon: Icons.table_chart_outlined,
        message: emptyMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Scrollbar(
              thumbVisibility: true,
              notificationPredicate: (notif) => notif.depth == 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 44,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 56,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    headingTextStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      color: Color(0xFF64748B),
                    ),
                    dataTextStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                    columns: columns.map((c) => DataColumn(
                      label: Text(c.label),
                      numeric: c.numeric,
                    )).toList(),
                    rows: data.map((row) {
                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return const Color(0xFFF1F5F9);
                          }
                          return Colors.white;
                        }),
                        onSelectChanged: onRowTap != null ? (_) => onRowTap!(row) : null,
                        cells: columns.map((c) {
                          if (c.cellBuilder != null) {
                            return DataCell(c.cellBuilder!(row));
                          }
                          final val = c.key != null && row is Map ? row[c.key] : '';
                          return DataCell(Text(val?.toString() ?? ''));
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
