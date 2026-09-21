import 'package:flutter/material.dart';

enum WorldView { states, rules }

/// What the author is looking at, kept per project so a return restores the
/// tab, the searches and the selections rather than the first document.
class WorldViewState {
  final factSearch = TextEditingController();
  final ruleSearch = TextEditingController();
  final invalidFields = <String>{};
  WorldView view = WorldView.states;
  bool libraryOpen = true, contextOpen = true;
  String factCategory = '';
  String? actionError;

  void dispose() {
    factSearch.dispose();
    ruleSearch.dispose();
  }
}
