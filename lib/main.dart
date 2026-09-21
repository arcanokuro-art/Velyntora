import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/project_storage.dart';
import 'theme/velyntora_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const VelyntoraApp());
}

class VelyntoraApp extends StatelessWidget {
  const VelyntoraApp({super.key, this.storage});

  final ProjectStorage? storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velyntora',
      debugShowCheckedModeBanner: false,
      theme: VelyntoraTheme.dark,
      home: HomeScreen(storage: storage),
    );
  }
}
