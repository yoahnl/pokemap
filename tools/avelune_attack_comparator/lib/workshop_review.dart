import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum WorkshopReviewStatus { toReview, issue, approved }

String workshopReviewKey(String id, {String? variant, String? asset}) =>
    jsonEncode([id, variant, asset]);

final class WorkshopReviewStore {
  WorkshopReviewStore(this.file);

  static final Map<String, Future<void>> _writes = {};
  final File file;
  Map<String, WorkshopReviewStatus> _reviews = {};
  int _sequence = 0;

  WorkshopReviewStatus statusFor(String key) =>
      _reviews[key] ?? WorkshopReviewStatus.toReview;

  Future<void> load() async {
    _reviews = await _read();
  }

  Future<void> save(String key, WorkshopReviewStatus status) {
    final path = file.absolute.path;
    final previous = _writes[path] ?? Future<void>.value();
    final result = previous.catchError((Object _) {}).then((_) => _save(key, status));
    _writes[path] = result;
    return result.whenComplete(() {
      if (identical(_writes[path], result)) _writes.remove(path);
    });
  }

  Future<void> _save(String key, WorkshopReviewStatus status) async {
    await file.parent.create(recursive: true);
    final lock = await File('${file.path}.lock').open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
      final reviews = await _read();
      if (status == WorkshopReviewStatus.toReview) {
        reviews.remove(key);
      } else {
        reviews[key] = status;
      }
      final temporary = File('${file.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.${_sequence++}.tmp');
      try {
        await temporary.writeAsString(jsonEncode({
          'schemaVersion': 1,
          'reviews': {for (final entry in reviews.entries) entry.key: entry.value.name},
        }), flush: true);
        await temporary.rename(file.path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
      _reviews = reviews;
    } finally {
      await lock.unlock();
      await lock.close();
    }
  }

  Future<Map<String, WorkshopReviewStatus>> _read() async {
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    if (content.length > 1024 * 1024) throw const FormatException('Review file is too large');
    final data = jsonDecode(content);
    if (data is! Map || data.length != 2 || data['schemaVersion'] != 1 || data['reviews'] is! Map) {
      throw const FormatException('Invalid review file');
    }
    final reviews = <String, WorkshopReviewStatus>{};
    for (final entry in (data['reviews'] as Map).entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('Invalid review entry');
      }
      final status = WorkshopReviewStatus.values.where((value) => value.name == entry.value).toList();
      if (status.length != 1) throw const FormatException('Unknown review status');
      reviews[entry.key as String] = status.single;
    }
    return reviews;
  }
}
