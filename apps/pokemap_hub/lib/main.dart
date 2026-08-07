import 'package:flutter/material.dart';

import 'package:pokemap_hub/app/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PokeMapHubBootstrap());
}
