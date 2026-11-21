final class EvaluationBuildProvenance {
  EvaluationBuildProvenance({required this.commit, required this.codeDigest}) {
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(commit) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(codeDigest)) {
      throw const FormatException('Invalid sealed evaluation provenance.');
    }
  }

  final String commit;
  final String codeDigest;
}
