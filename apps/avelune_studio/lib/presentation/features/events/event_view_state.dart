import 'package:flutter/material.dart';

enum EventTab { trigger, conditions, scene, options }

class EventViewState {
  final search = TextEditingController();
  final scroll = ScrollController();
  final transforms = <String, TransformationController>{};
  EventTab tab = EventTab.trigger;
  String? filterMapId;
  bool onMapOnly = false;
  bool library = false;
  bool inspector = false;
  final fitted = <String>{};
  final invalidNumbers = <String, String>{};

  TransformationController transform(String id) =>
      transforms.putIfAbsent(id, TransformationController.new);

  void dispose() {
    search.dispose();
    scroll.dispose();
    for (final transform in transforms.values) {
      transform.dispose();
    }
  }
}
