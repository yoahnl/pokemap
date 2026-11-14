enum ResourcePackTransferDirection { importing, exporting }

enum ResourcePackTransferPhase {
  idle,
  picking,
  inspecting,
  selecting,
  preparing,
  preview,
  applying,
  building,
  writing,
  publishing,
  publicationRequired,
  complete,
  reconciliationRequired,
  recoveryRequired,
  closed,
}
