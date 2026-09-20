import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/velyntora_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VelyntoraApp());
}

class VelyntoraApp extends StatelessWidget {
  const VelyntoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velyntora',
      debugShowCheckedModeBanner: false,
      theme: VelyntoraTheme.dark,
      home: const HomeScreen(),
    );
  }
}
