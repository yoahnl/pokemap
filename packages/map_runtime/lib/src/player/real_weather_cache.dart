import 'dart:convert';
import 'dart:io';
import 'package:map_core/map_core.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class RealWeatherCache {
  Future<RealWeatherSnapshot?> read();
  Future<void> write(RealWeatherSnapshot snapshot);
}
final class FileRealWeatherCache implements RealWeatherCache {
  FileRealWeatherCache({Future<File> Function()? file}) : _file = file ?? _defaultFile;
  final Future<File> Function() _file;
  static int _sequence = 0;
  static Future<File> _defaultFile() async => File('${(await getApplicationSupportDirectory()).path}/avelune/weather/current-v1.json');
  @override
  Future<RealWeatherSnapshot?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    if (await file.length() > 32768) throw const FormatException('Weather cache too large.');
    return RealWeatherSnapshot.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
  }
  @override
  Future<void> write(RealWeatherSnapshot snapshot) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.pending-$pid-${_sequence++}');
    try {
      await temporary.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
      await temporary.rename(file.path);
    } finally { if (await temporary.exists()) await temporary.delete(); }
  }
}
