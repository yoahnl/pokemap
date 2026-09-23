part of 'ui05_narrative_fixture.dart';

class Ui05NarrativePort implements NarrativePort, NarrativeArtworkPort {
  Ui05NarrativePort(this.port, this.tester);
  final NarrativePort port;
  final WidgetTester tester;
  int dialogueReads = 0;
  int publications = 0;
  @override
  Future<Uint8List?> readArtwork(NarrativeArtworkKind kind, {String? id}) {
    final artwork = port;
    if (artwork is! NarrativeArtworkPort) return Future.value();
    return (artwork as NarrativeArtworkPort).readArtwork(kind, id: id);
  }

  Future<T> run<T>(Future<T> Function() action) async =>
      (await WidgetResourcePort.serial(tester, action))!;

  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) {
    dialogueReads++;
    return run(() => port.readDialogue(entry));
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) {
    publications++;
    return run(() => port.publish(publication));
  }
}
