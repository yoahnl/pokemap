import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'event_labels.dart';

class EventStatusBadge extends StatelessWidget {
  const EventStatusBadge({super.key, required this.record, this.dirty = false});
  final NarrativeEventRecord record;
  final bool dirty;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: StudioBadge(
      '${dirty ? 'Modifications locales · ' : ''}${eventStateLabel(record)}',
      tone: eventStateTone(record, dirty: dirty),
      icon: dirty
          ? Icons.edit_outlined
          : record.enabledOrNull == true
          ? Icons.check_circle_outline
          : Icons.circle_outlined,
    ),
  );
}
