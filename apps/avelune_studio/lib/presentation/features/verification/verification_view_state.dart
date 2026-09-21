import 'package:flutter/material.dart';

/// What the author is looking at, kept by the host so a return restores the
/// filters, the selection, the scroll and the graph framing rather than the
/// first diagnostic of a fresh page.
class VerificationViewState {
  final search = TextEditingController();
  final listScroll = ScrollController();
  final graphTransform = TransformationController();
  bool summaryOpen = true, detailOpen = true;
  bool limitationsOpen = false;

  void dispose() {
    search.dispose();
    listScroll.dispose();
    graphTransform.dispose();
  }
}
