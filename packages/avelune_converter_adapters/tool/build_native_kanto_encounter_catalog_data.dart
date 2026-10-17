import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/native_encounter_catalog_qualification.dart';

Future<void> main() async {
  final bundle =
      await File('assets/native_kanto_encounter_bundle.json').readAsBytes();
  final qualification =
      await File('assets/native_kanto_encounter_qualification.json')
          .readAsBytes();
  NativeEncounterCatalogQualification.kantoV1(
      bundleBytes: bundle, attestationBytes: qualification);
  final output =
      File('lib/src/generated/native_kanto_encounter_catalog_data.dart');
  await output.writeAsString(
      "const nativeKantoEncounterBundleJson = r'''${utf8.decode(bundle)}''';\n\n"
      "const nativeKantoEncounterQualificationJson = r'''${utf8.decode(qualification)}''';\n");
  stdout.writeln(
      'Verified and embedded the exact closed Kanto encounter release.');
}
