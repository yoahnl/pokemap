import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/main.dart' as studio;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Studio template catalog loads from the Hub dependency asset bundle',
    () async {
      final canonical = await File(
        '../../packages/map_authoring/assets/project_templates.v1.json',
      ).readAsString();
      final bundled = await rootBundle.loadString(
        'packages/map_authoring/assets/project_templates.v1.json',
      );
      final catalog = await studio.loadStudioProjectTemplateCatalog();

      expect(jsonDecode(bundled), jsonDecode(canonical));
      expect(catalog.toJson(), jsonDecode(canonical));
    },
  );
}
