import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'drift_db.dart';

class DbTestPage extends StatefulWidget {
  const DbTestPage({super.key});

  @override
  State<DbTestPage> createState() => _DbTestPageState();
}

class _DbTestPageState extends State<DbTestPage> {
  String _supabaseStatus = 'Not tested';
  String _driftStatus = 'Not tested';
  bool _loading = false;

  Future<void> _runTests() async {
    setState(() => _loading = true);

    // --- Supabase test ---
    try {
      final client = Supabase.instance.client;
      // A simple ping: list tables from the public schema.
      // Will return [] if schema is empty, or throw if URL/key is wrong.
      await client.from('profiles').select('id').limit(1);
      setState(() => _supabaseStatus = 'Connected (profiles table reachable)');
    } on PostgrestException catch (e) {
      // 42P01 = table does not exist — connection is fine, just no schema yet
      if (e.code == '42P01') {
        setState(() =>
            _supabaseStatus = 'Connected (run the schema SQL in Supabase dashboard)');
      } else {
        setState(() => _supabaseStatus = 'Error: ${e.message}');
      }
    } catch (e) {
      setState(() => _supabaseStatus = 'Error: $e');
    }

    // --- Drift test ---
    try {
      final db = AppDatabase();
      // schemaVersion=1 means Drift opened/created the SQLite file successfully
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
            _StatusRow(label: 'Supabase', value: _supabaseStatus),
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
