import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';
import 'package:laundrypro_uae/core/theme.dart';
import '../models/employee_model.dart';
import '../services/operator_service.dart';

class OperatorScreen extends ConsumerStatefulWidget {
  const OperatorScreen({super.key, this.operatorService});

  final OperatorService? operatorService;

  @override
  ConsumerState<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends ConsumerState<OperatorScreen> {
  bool _isLoading = false;
  List<dynamic> _certs = [];
  List<EmployeeModel> _employees = [];
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'active', 'expired', 'warning'
  final TextEditingController _searchController = TextEditingController();

  OperatorService get _service =>
      widget.operatorService ?? ref.read(operatorServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final certsFuture = _service.listCertifications();
      final empFuture = _service.listEmployees();

      final results = await Future.wait([certsFuture, empFuture]);
      if (mounted) {
        setState(() {
          _certs = results[0];
          _employees = results[1] as List<EmployeeModel>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredCerts {
    final now = DateTime.now();
    return _certs.where((c) {
      final empName = (c['full_name'] ?? c['employee_name'] ?? '').toString().toLowerCase();
      final badge = (c['employee_no'] ?? c['badge_id'] ?? '').toString().toLowerCase();
      final certName = (c['certification_name'] ?? c['certification_type'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesSearch = q.isEmpty ||
          empName.contains(q) ||
          badge.contains(q) ||
          certName.contains(q);

      final expiryStr = c['expires_at'] ?? c['expiry_date'];
      final expiryDate = expiryStr != null ? DateTime.tryParse(expiryStr.toString()) : null;

      final isExpired = expiryDate != null && expiryDate.isBefore(now);
      final isWarning = expiryDate != null &&
          !isExpired &&
          expiryDate.isBefore(now.add(const Duration(days: 30)));

      final matchesStatus = switch (_filterStatus) {
        'active' => !isExpired && !isWarning,
        'warning' => isWarning,
        'expired' => isExpired,
        _ => true,
      };

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _showCertifyDialog() async {
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No employees found to certify. Add employees first.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    EmployeeModel? selectedEmployee = _employees.first;
    final certTypes = [
      'Cleanroom Level 1 — Basic Hygiene & Gowning',
      'Cleanroom Level 2 — ISO Class 7 Protocol & Aseptic',
      'Bio-Contamination & Sterilization Operator',
      'Thermal Autoclave & Pressure Chamber Validation',
      'Hazardous Detergent & Chemical Handling'
    ];
    String selectedCert = certTypes[0];
    DateTime issuedDate = DateTime.now();
    DateTime expiryDate = DateTime.now().add(const Duration(days: 365));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_outlined, color: AppTheme.accentTeal),
              SizedBox(width: 8),
              Text('Issue Operator Certification', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<EmployeeModel>(
                  initialValue: selectedEmployee,
                  decoration: const InputDecoration(
                    labelText: 'Select Employee *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: _employees.map((emp) {
                    return DropdownMenuItem(
                      value: emp,
                      child: Text('${emp.fullName} (${emp.employeeNo})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedEmployee = val);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCert,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Certification Program *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: certTypes.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCert = val);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Issue Date: ${issuedDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Change Issue Date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: issuedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => issuedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Expiration Date: ${expiryDate.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 16),
                  label: const Text('Change Expiration Date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expiryDate,
                      firstDate: issuedDate,
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => expiryDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentTeal,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Issue Certificate'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedEmployee != null) {
      try {
        final payload = {
          'certification_name': selectedCert,
          'issued_at': issuedDate.toIso8601String().split('T')[0],
          'expires_at': expiryDate.toIso8601String().split('T')[0],
        };
        await _service.certify(selectedEmployee!.id, payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operator certified successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to certify: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  void _showCertDetails(Map<String, dynamic> c) {
    final name = c['full_name'] ?? c['employee_name'] ?? 'Certified Operator';
    final badge = c['employee_no'] ?? c['badge_id'] ?? 'N/A';
    final certName = c['certification_name'] ?? c['certification_type'] ?? 'Cleanroom Standard';
    final issued = c['issued_at'] ?? 'N/A';
    final expiry = c['expires_at'] ?? c['expiry_date'] ?? 'N/A';

    final expiryDate = expiry != 'N/A' ? DateTime.tryParse(expiry.toString()) : null;
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? AppTheme.errorRed.withValues(alpha: 0.12)
                          : AppTheme.accentTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isExpired ? 'EXPIRED' : 'VALID',
                      style: TextStyle(
                        color: isExpired ? AppTheme.errorRed : AppTheme.accentTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _detailRow('Employee Badge', badge),
              _detailRow('Certification Program', certName),
              _detailRow('Date Issued', issued),
              _detailRow('Valid Until', expiry),
              _detailRow('Record ID', '#${c['id'] ?? 'N/A'}'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Close'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _filteredCerts;
    final now = DateTime.now();

    final activeCount = _certs.where((c) {
      final exp = c['expires_at'] ?? c['expiry_date'];
      final d = exp != null ? DateTime.tryParse(exp.toString()) : null;
      return d == null || (!d.isBefore(now) && !d.isBefore(now.add(const Duration(days: 30))));
    }).length;

    final warningCount = _certs.where((c) {
      final exp = c['expires_at'] ?? c['expiry_date'];
      final d = exp != null ? DateTime.tryParse(exp.toString()) : null;
      return d != null && !d.isBefore(now) && d.isBefore(now.add(const Duration(days: 30)));
    }).length;

    final expiredCount = _certs.where((c) {
      final exp = c['expires_at'] ?? c['expiry_date'];
      final d = exp != null ? DateTime.tryParse(exp.toString()) : null;
      return d != null && d.isBefore(now);
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('operators_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Certify Operator'),
        onPressed: _showCertifyDialog,
      ),
      body: Column(
        children: [
          // Filter & Search
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search operator name, badge ID, certification...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(label: 'All (${_certs.length})', value: 'all'),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: 'Valid ($activeCount)',
                        value: 'active',
                        badgeColor: AppTheme.accentTeal,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: 'Expiring Soon ($warningCount)',
                        value: 'warning',
                        badgeColor: AppTheme.warningOrange,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: 'Expired ($expiredCount)',
                        value: 'expired',
                        badgeColor: AppTheme.errorRed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 48,
                              color: AppTheme.secondaryGrey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _certs.isEmpty
                                  ? l10n.t('reports_empty')
                                  : 'No operator certifications match current filter',
                              style: const TextStyle(color: AppTheme.secondaryGrey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final raw = filtered[index];
                            final c = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                            final name = c['full_name'] ?? c['employee_name'] ?? 'Certified Operator';
                            final badge = c['employee_no'] ?? c['badge_id'] ?? 'OP-0${index + 1}';
                            final certType = c['certification_name'] ?? c['certification_type'] ?? 'Cleanroom Level 2';
                            final expiry = c['expires_at'] ?? c['expiry_date'] ?? '2027-12-31';

                            final expDate = DateTime.tryParse(expiry.toString());
                            final isExpired = expDate != null && expDate.isBefore(now);
                            final isWarning = expDate != null &&
                                !isExpired &&
                                expDate.isBefore(now.add(const Duration(days: 30)));

                            final statusBadgeColor = isExpired
                                ? AppTheme.errorRed
                                : isWarning
                                    ? AppTheme.warningOrange
                                    : AppTheme.accentTeal;

                            final statusBadgeText = isExpired
                                ? 'EXPIRED'
                                : isWarning
                                    ? 'EXPIRING'
                                    : 'CERTIFIED';

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isExpired
                                      ? AppTheme.errorRed.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showCertDetails(c),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: statusBadgeColor.withValues(alpha: 0.12),
                                        child: Icon(Icons.badge, color: statusBadgeColor),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '$certType • Badge: $badge',
                                              style: const TextStyle(
                                                color: AppTheme.secondaryGrey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Expires: $expiry',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isExpired ? AppTheme.errorRed : AppTheme.secondaryGrey,
                                                fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusBadgeColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          statusBadgeText,
                                          style: TextStyle(
                                            color: statusBadgeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    Color? badgeColor,
  }) {
    final isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (badgeColor ?? AppTheme.primaryNavy).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? (badgeColor ?? AppTheme.primaryNavy) : AppTheme.secondaryGrey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _filterStatus = value);
      },
    );
  }
}
