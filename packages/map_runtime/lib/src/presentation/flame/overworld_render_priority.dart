const int overworldBackgroundRenderPriority = -(1 << 30);
const int overworldForegroundRenderPriority = 100000;

int overworldActorRenderPriority(
  double worldDepthY, {
  int tieBreaker = 0,
}) {
  final priority = 1000 + worldDepthY.round() + tieBreaker;
  if (priority <= overworldBackgroundRenderPriority) {
    return overworldBackgroundRenderPriority + 1;
  }
  if (priority >= overworldForegroundRenderPriority) {
    return overworldForegroundRenderPriority - 1;
  }
  return priority;
}
