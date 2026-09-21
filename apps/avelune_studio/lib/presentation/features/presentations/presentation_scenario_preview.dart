import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

abstract interface class PresentationScenarioPreview implements Listenable {
  bool get running;
  bool get waitingForInteraction;
  String get statusLabel;
  Object? get failure;
  NewGameDraft? get result;
  Widget surface();
  Future<void> run({String? playerName});
  Future<void> stop();
  Future<void> close();
}
