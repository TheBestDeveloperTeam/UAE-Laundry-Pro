import 'package:flutter/material.dart';
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
      return const Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty) {
      return EmptyState(
        icon: Icons.table_chart_outlined,
        message: emptyMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: columns.map((c) => DataColumn(
                label: Text(c.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                numeric: c.numeric,
              )).toList(),
              rows: data.map((row) {
                return DataRow(
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
        );
      },
    );
  }
}
