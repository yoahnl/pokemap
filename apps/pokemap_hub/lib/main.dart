import 'package:flutter/material.dart';

import 'src/bootstrap/hub_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PokeMapHubBootstrap());
}
