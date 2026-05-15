enum RuntimeShadowRenderOrderSlot {
  baseTerrain,
  groundPaths,
  surfaceLayers,
  futureStaticPlacedElementShadows,
  futureDynamicActorContactShadows,
  placedElementSprites,
  actorsPlayerNpc,
  placedElementOcclusionPatches,
  debugOverlays,
  hudUi,
}

const runtimeShadowRenderOrder = <RuntimeShadowRenderOrderSlot>[
  RuntimeShadowRenderOrderSlot.baseTerrain,
  RuntimeShadowRenderOrderSlot.groundPaths,
  RuntimeShadowRenderOrderSlot.surfaceLayers,
  RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
  RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
  RuntimeShadowRenderOrderSlot.placedElementSprites,
  RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
  RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
  RuntimeShadowRenderOrderSlot.debugOverlays,
  RuntimeShadowRenderOrderSlot.hudUi,
];

int runtimeShadowSlotIndex(RuntimeShadowRenderOrderSlot slot) =>
    runtimeShadowRenderOrder.indexOf(slot);

bool runtimeShadowSlotIsBefore(
  RuntimeShadowRenderOrderSlot a,
  RuntimeShadowRenderOrderSlot b,
) =>
    runtimeShadowSlotIndex(a) < runtimeShadowSlotIndex(b);

bool runtimeShadowSlotIsAfter(
  RuntimeShadowRenderOrderSlot a,
  RuntimeShadowRenderOrderSlot b,
) =>
    runtimeShadowSlotIndex(a) > runtimeShadowSlotIndex(b);
