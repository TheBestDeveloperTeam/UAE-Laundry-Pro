import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/operator_service.dart';

class OperatorScreen extends ConsumerStatefulWidget {
  const OperatorScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends ConsumerState<OperatorScreen> {
  bool _isLoading = false;
  List<dynamic> _certs = [];

  @override
  void initState() {
    super.initState();
    _loadCerts();
  }

  Future<void> _loadCerts() async {
    setState(() => _isLoading = true);
    try {
      final s = ref.read(operatorServiceProvider);
      final list = await s.listCertifications();
      if (mounted) setState(() => _certs = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Certifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCerts,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _certs.length,
            itemBuilder: (context, index) {
              final c = _certs[index];
              return ListTile(
                title: Text('\ (\)'),
                subtitle: Text('\ - Expires: \'),
                leading: const Icon(Icons.badge),
              );
            },
          ),
    );
  }
}

