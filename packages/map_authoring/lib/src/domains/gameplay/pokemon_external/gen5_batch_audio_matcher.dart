final class Gen5BatchAudioMatch {
  const Gen5BatchAudioMatch(this.fileName, this.warnings);
  final String? fileName;
  final Set<String> warnings;
}

abstract final class Gen5BatchAudioMatcher {
  static String _normalize(String value) => value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  static Gen5BatchAudioMatch select(String moveId, Iterable<String> fileNames) {
    final target = _normalize(moveId);
    final candidates = fileNames.where((name) => name.toLowerCase().endsWith('.mp3')).toList();
    List<String> matching(String value) => candidates.where((name) =>
      _normalize(name.substring(0, name.length - 4)) == value).toList();
    final exact = matching(target);
    if (exact.length == 1) return Gen5BatchAudioMatch(exact.single, const {});
    if (exact.length > 1) return const Gen5BatchAudioMatch(null, {'ambiguous-move-audio'});
    final oneHit = matching('${target}1hit');
    if (oneHit.length == 1) return Gen5BatchAudioMatch(oneHit.single, const {'sound-multihit-one-hit-preview'});
    if (oneHit.length > 1) return const Gen5BatchAudioMatch(null, {'ambiguous-move-audio'});
    return const Gen5BatchAudioMatch(null, {});
  }
}
