import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/feedback/studio_badge.dart';

export '../../../features/events/application/event_labels.dart';

StudioTone eventKindTone(NarrativeEventSourceKind? kind) => switch (kind) {
  NarrativeEventSourceKind.entityAutorun => StudioTone.feature,
  NarrativeEventSourceKind.entityBump => StudioTone.info,
  NarrativeEventSourceKind.entityInteract => StudioTone.info,
  NarrativeEventSourceKind.modelInteract => StudioTone.info,
  NarrativeEventSourceKind.triggerBump => StudioTone.info,
  NarrativeEventSourceKind.triggerEnter => StudioTone.success,
  NarrativeEventSourceKind.mapEnter => StudioTone.feature,
  NarrativeEventSourceKind.outcomeReceived => StudioTone.warning,
  null => StudioTone.neutral,
};

StudioTone eventStateTone(NarrativeEventRecord record, {bool dirty = false}) =>
    dirty || record.draftOrNull != null
    ? StudioTone.warning
    : record.enabledOrNull == true
    ? StudioTone.success
    : StudioTone.neutral;

IconData eventKindIcon(NarrativeEventSourceKind? kind) => switch (kind) {
  NarrativeEventSourceKind.entityAutorun => Icons.play_circle_outline,
  NarrativeEventSourceKind.entityBump => Icons.touch_app_outlined,
  NarrativeEventSourceKind.entityInteract => Icons.forum_outlined,
  NarrativeEventSourceKind.modelInteract => Icons.view_in_ar_outlined,
  NarrativeEventSourceKind.triggerBump => Icons.touch_app_outlined,
  NarrativeEventSourceKind.triggerEnter => Icons.crop_free,
  NarrativeEventSourceKind.mapEnter => Icons.login,
  NarrativeEventSourceKind.outcomeReceived => Icons.flag_outlined,
  null => Icons.add_location_alt_outlined,
};
