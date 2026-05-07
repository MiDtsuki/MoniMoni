import 'package:flutter/material.dart';

class DbTestPage extends StatelessWidget {
  const DbTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Local database diagnostics are unavailable on web.'),
        ),
      ),
    );
  }
}
