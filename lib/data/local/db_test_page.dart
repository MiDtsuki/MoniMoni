import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/firebase/user_records.dart';
import 'drift_db.dart';

class DbTestPage extends StatefulWidget {
  const DbTestPage({super.key});

  @override
  State<DbTestPage> createState() => _DbTestPageState();
}

class _DbTestPageState extends State<DbTestPage> {
  String _firebaseStatus = 'Not tested';
  String _driftStatus = 'Not tested';
  bool _loading = false;

  Future<void> _runTests() async {
    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection(userProfilesCollection)
          .limit(1)
          .get();
      setState(() => _firebaseStatus = 'Connected (user_profiles reachable)');
    } catch (e) {
      setState(() => _firebaseStatus = 'Error: $e');
    }

    try {
      final db = AppDatabase();
      final version = db.schemaVersion;
      await db.close();
      setState(() => _driftStatus = 'OK (schema v$version, SQLite file created)');
    } catch (e) {
      setState(() => _driftStatus = 'Error: $e');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backend & DB Test')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(label: 'Firebase', value: _firebaseStatus),
            const SizedBox(height: 16),
            _StatusRow(label: 'Drift (SQLite)', value: _driftStatus),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _runTests,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Run Tests'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ok = value.startsWith('Connected') || value.startsWith('OK');
    final error = value.startsWith('Error');
    final color = ok
        ? const Color(0xFF4CAF7D)
        : error
            ? Colors.red
            : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              ok
                  ? Icons.check_circle
                  : error
                      ? Icons.error
                      : Icons.circle_outlined,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: TextStyle(color: color))),
          ],
        ),
      ],
    );
  }
}
