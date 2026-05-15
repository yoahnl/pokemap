enum EditorShadowRenderOrderSlot {
  baseTerrain,
  groundPaths,
  surfacePreview,
  futureStaticElementShadows,
  futureDynamicActorShadows,
  placedElementsBackground,
  actorsOrEntitiesBackground,
  placedElementsForeground,
  actorsOrEntitiesForeground,
  foregroundOcclusion,
  debugAndSelectionOverlays,
  flutterUi,
}

const editorShadowRenderOrder = <EditorShadowRenderOrderSlot>[
  EditorShadowRenderOrderSlot.baseTerrain,
  EditorShadowRenderOrderSlot.groundPaths,
  EditorShadowRenderOrderSlot.surfacePreview,
  EditorShadowRenderOrderSlot.futureStaticElementShadows,
  EditorShadowRenderOrderSlot.futureDynamicActorShadows,
  EditorShadowRenderOrderSlot.placedElementsBackground,
  EditorShadowRenderOrderSlot.actorsOrEntitiesBackground,
  EditorShadowRenderOrderSlot.placedElementsForeground,
  EditorShadowRenderOrderSlot.actorsOrEntitiesForeground,
  EditorShadowRenderOrderSlot.foregroundOcclusion,
  EditorShadowRenderOrderSlot.debugAndSelectionOverlays,
  EditorShadowRenderOrderSlot.flutterUi,
];

int editorShadowSlotIndex(EditorShadowRenderOrderSlot slot) =>
    editorShadowRenderOrder.indexOf(slot);

bool editorShadowSlotIsBefore(
  EditorShadowRenderOrderSlot a,
  EditorShadowRenderOrderSlot b,
) =>
    editorShadowSlotIndex(a) < editorShadowSlotIndex(b);

bool editorShadowSlotIsAfter(
  EditorShadowRenderOrderSlot a,
  EditorShadowRenderOrderSlot b,
) =>
    editorShadowSlotIndex(a) > editorShadowSlotIndex(b);
