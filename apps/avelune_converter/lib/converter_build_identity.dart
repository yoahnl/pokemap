class ConverterBuildIdentity {
  ConverterBuildIdentity({
    this.version = '0.1.0',
    this.buildNumber = '1',
    String revision = '',
  }) : revision =
           revision.length == 40 &&
               RegExp(r'^[0-9a-fA-F]{40}$').hasMatch(revision)
           ? revision.toLowerCase()
           : null;

  static final current = ConverterBuildIdentity(
    version: const String.fromEnvironment(
      'AVELUNE_CONVERTER_VERSION',
      defaultValue: '0.1.0',
    ),
    buildNumber: const String.fromEnvironment(
      'AVELUNE_CONVERTER_BUILD_NUMBER',
      defaultValue: '1',
    ),
    revision: const String.fromEnvironment('AVELUNE_CONVERTER_REVISION'),
  );

  final String version;
  final String buildNumber;
  final String? revision;

  String get label =>
      'Version $version+$buildNumber\n'
      '${revision == null ? 'Compilation locale' : 'Révision ${revision!.substring(0, 9)}'}';
}
