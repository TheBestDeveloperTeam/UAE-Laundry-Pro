import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laundrypro_uae/core/logger.dart';

/// Collapsible debug console accordion widget.
/// Default: collapsed (non-technical users won't see clutter).
/// Expanded: displays real-time execution logs, timestamps, errors, with copy-to-clipboard.
class DebugConsoleAccordion extends StatefulWidget {
  final bool initialExpanded;
  final double maxHeight;

  const DebugConsoleAccordion({
    super.key,
    this.initialExpanded = false,
    this.maxHeight = 220,
  });

  @override
  State<DebugConsoleAccordion> createState() => _DebugConsoleAccordionState();
}

class _DebugConsoleAccordionState extends State<DebugConsoleAccordion> {
  late bool _expanded;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialExpanded;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyAllLogs(List<LogEntry> logs) {
    final text = logs.map((e) => e.formatted()).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LogEntry>>(
      valueListenable: AppLogger.logBuffer,
      builder: (context, logs, _) {
        return Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E242B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 16,
                        color: Colors.tealAccent.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Technical Diagnostics & Process Logs (${logs.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const Spacer(),
                      if (_expanded && logs.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                          tooltip: 'Copy all logs',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _copyAllLogs(logs),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const Divider(height: 1, color: Colors.black45),
                Container(
                  constraints: BoxConstraints(maxHeight: widget.maxHeight),
                  color: const Color(0xFF14181D),
                  padding: const EdgeInsets.all(10),
                  child: logs.isEmpty
                      ? Center(
                          child: Text(
                            'No logs captured yet.',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        )
                      : Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            itemCount: logs.length,
                            itemBuilder: (context, idx) {
                              final entry = logs[idx];
                              Color textColor = Colors.white70;
                              if (entry.level == 'ERROR') {
                                textColor = Colors.redAccent;
                              } else if (entry.level == 'WARN') {
                                textColor = Colors.amberAccent;
                              } else if (entry.level == 'INFO') {
                                textColor = Colors.lightBlueAccent;
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: SelectableText(
                                  entry.formatted(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Consolas, monospace',
                                    color: textColor,
                                    height: 1.3,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

