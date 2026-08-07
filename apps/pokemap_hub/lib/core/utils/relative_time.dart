/// Relative time wording shared by every Avelune home surface.
///
/// The recent activity rail and the hero details panel both render "how long
/// ago", so the phrasing lives here instead of being duplicated per widget.
String aveluneRelativeTime(
  DateTime occurredAt,
  DateTime now, {
  required bool french,
}) {
  final difference = now.difference(occurredAt);
  if (difference.isNegative || difference.inMinutes < 1) {
    return french ? 'à l\'instant' : 'just now';
  }
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return french ? 'il y a $minutes min' : '$minutes min ago';
  }
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return french ? 'il y a $hours h' : '$hours h ago';
  }
  if (difference.inDays == 1) {
    return french ? 'hier' : 'yesterday';
  }
  if (difference.inDays < 7) {
    final days = difference.inDays;
    return french ? 'il y a $days j' : '$days d ago';
  }
  return '${occurredAt.day}/${occurredAt.month}';
}
