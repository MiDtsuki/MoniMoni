import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class MoniApp extends StatelessWidget {
  const MoniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Moni',
      debugShowCheckedModeBanner: false,
      theme: MoniTheme.light,
      routerConfig: appRouter,
    );
  }
}
