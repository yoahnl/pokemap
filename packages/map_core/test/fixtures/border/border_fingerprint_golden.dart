// These canonical JSON preimages were produced and cross-checked independently
// from the Dart fingerprint implementation. Adjacent literals concatenate
// without adding whitespace or line breaks.
const String borderBlueprintCanonicalJsonGolden =
    '{"blueprintId":"blueprint-a","defaults":{"depthRows":2,"detailDensityPermill'
    'e":200,"gapTolerancePx":5,"irregularityPermille":100,"maxOverlapPx":4,"varia'
    'tionPermille":300},"ground":{"edgeBandCells":2,"visualSnapshotIdsByRole":{"c'
    'ornerNE":"border-snapshot-sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbbbbbbbb","cornerNW":"border-snapshot-sha256:aaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","cornerSE":"border-snapshot-'
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","co'
    'rnerSW":"border-snapshot-sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbbbbbbb","cross":"border-snapshot-sha256:bbbbbbbbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","endEast":"border-snapshot-sha25'
    '6:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","endNort'
    'h":"border-snapshot-sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbb","endSouth":"border-snapshot-sha256:bbbbbbbbbbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","endWest":"border-snapshot-sha256:'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","horizonta'
    'l":"border-snapshot-sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbb","innerCornerNE":"border-snapshot-sha256:bbbbbbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","innerCornerNW":"border-snaps'
    'hot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"'
    ',"innerCornerSE":"border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaa","innerCornerSW":"border-snapshot-sha256:bbbbb'
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","isolated":"bor'
    'der-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    'aaaaaaaa","teeEast":"border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","teeNorth":"border-snapshot-sha256:bbbbbbb'
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","teeSouth":"borde'
    'r-snapshot-sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    'bbbbbb","teeWest":"border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","vertical":"border-snapshot-sha256:aaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}},"primitives":[{"a'
    'nchorPx":{"x":8,"y":15},"id":"a","publishedMetrics":{"assetFingerprint":"ass'
    'et-a","defaultAnchorPx":{"x":8,"y":19},"occupancyMaskRle":"border-rle-v1:2:1'
    ':1,1","opaqueBounds":{"height":18,"width":14,"x":1,"y":2},"pixelSize":{"heig'
    'ht":20,"width":16}},"role":"structureLarge","transforms":{"allowFlipX":true,'
    '"allowedQuarterTurns":[0,2]},"visualSnapshotId":"border-snapshot-sha256:aaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","weight":700},'
    '{"anchorPx":{"x":8,"y":15},"id":"b","publishedMetrics":{"assetFingerprint":"'
    'asset-b","defaultAnchorPx":{"x":8,"y":19},"occupancyMaskRle":"border-rle-v1:'
    '2:1:1,1","opaqueBounds":{"height":18,"width":14,"x":1,"y":2},"pixelSize":{"h'
    'eight":20,"width":16}},"role":"filler","transforms":{"allowFlipX":true,"allo'
    'wedQuarterTurns":[0,2]},"visualSnapshotId":"border-snapshot-sha256:bbbbbbbbb'
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","weight":300}],"rev'
    'ision":2,"template":"organicEdge"}';

const String borderGeometryAndSeedCanonicalJsonGolden =
    '{"featureId":"feature-a","geometry":{"cellsRle":"border-rle-v1:4:1:1,1,2","h'
    'eight":2,"kind":"region","width":2},"seed":"7"}';

const String borderParametersCanonicalJsonGolden =
    '{"depthRows":2,"detailDensityPermille":200,"gapTolerancePx":5,"irregularityP'
    'ermille":100,"maxOverlapPx":4,"variationPermille":300}';

const String borderOverridesCanonicalJsonGolden =
    '{"overrides":[{"locked":false,"lockedPlacement":null,"offsetDeltaPx":{"x":-2'
    ',"y":3},"replacementPrimitiveId":"a","slotKey":"slot-a","suppressed":false,"'
    'transformOverride":{"flipX":true,"quarterTurns":2},"variationSalt":"-9223372'
    '036854775808"},{"locked":false,"lockedPlacement":null,"offsetDeltaPx":{"x":-'
    '2,"y":3},"replacementPrimitiveId":"a","slotKey":"slot-z","suppressed":false,'
    '"transformOverride":{"flipX":true,"quarterTurns":2},"variationSalt":"9223372'
    '036854775807"}]}';

const String borderKeepOutRegionsCanonicalJsonGolden =
    '{"keepOutRegions":[{"id":"a","region":{"cellsRle":"border-rle-v1:2:1:1,1","h'
    'eight":1,"kind":"region","width":2}},{"id":"z","region":{"cellsRle":"border-'
    'rle-v1:2:0:1,1","height":1,"kind":"region","width":2}}]}';

const String borderMapContextCanonicalJsonGolden =
    '{"mapHeight":20,"mapWidth":30,"tileHeightPx":16,"tileWidthPx":16}';

const String borderVisualSnapshotsCanonicalJsonGolden =
    '{"visualSnapshots":[{"contentFingerprint":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","frames":[{"durationMs":100,"relativeAssetP'
    'ath":"assets/borders/snapshots/frame.png","sourceRectPx":{"height":16,"width'
    '":16,"x":1,"y":2},"transparentColorArgb":4278255360}],"id":"border-snapshot-'
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},{"'
    'contentFingerprint":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    'bbbbbbbbb","frames":[{"durationMs":100,"relativeAssetPath":"assets/borders/s'
    'napshots/frame.png","sourceRectPx":{"height":16,"width":16,"x":1,"y":2},"tra'
    'nsparentColorArgb":4278255360}],"id":"border-snapshot-sha256:bbbbbbbbbbbbbbb'
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}]}';

const String borderAggregateInputCanonicalJsonGolden =
    '{"blueprintRevision":2,"components":{"blueprint":"sha256:2ec2feae26e96747143'
    'd4c9478ef5f2cd0e59a827914fb3b2c1c4f0846260d22","geometryAndSeed":"sha256:b4d'
    '01a324035e02af317810d548283a86e0e63d06a9c21ba5de6c0ce65fde9aa","keepOutRegio'
    'ns":"sha256:47f2973b6303863624b5fe9e31e8af76cc95ccbf15b4138a3f98d4c8ff6b0d76'
    '","mapContext":"sha256:4a0ea904799cd02f8be700539b18187e9e81bf04130403a047536'
    '2f6d56e1291","overrides":"sha256:63ddf51388c17a60ae5d74bb22ed8c714d8fbd4c454'
    '537b00a751deb522589f2","parameters":"sha256:112c07cbbd852522556d3cf49dea7bae'
    '42ca740c43b16a0ce755dc1cf64870e9","visualSnapshots":"sha256:1cfa15a939a79636'
    '2ed823785174edb3062d9ace179c7d22bd85a07f1388868e"},"resolverVersion":1}';

const String borderOutputCanonicalJsonGolden =
    '{"ground":[{"resolvedRole":"endEast","visualSnapshotId":"border-snapshot-sha'
    '256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","x":0,'
    '"y":2},{"resolvedRole":"endWest","visualSnapshotId":"border-snapshot-sha256:'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","x":1,"y":'
    '2}],"placements":[{"anchorCell":{"x":1,"y":2},"drawBand":"structure","id":"p'
    'lacement-a","opaqueWorldBoundsPx":{"height":18,"width":14,"x":17,"y":34},"pr'
    'imitiveId":"a","slotKey":"slot-a","stableOrderKey":{"anchorRowMajor":10,"dra'
    'wBandIndex":1,"ordinalLocal":3,"passIndex":1,"rank":2,"slotKey":"slot-a"},"t'
    'opLeftWorldPx":{"x":16,"y":32},"transform":{"flipX":true,"quarterTurns":2},"'
    'visualSnapshotId":"border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},{"anchorCell":{"x":1,"y":2},"drawBand":"str'
    'ucture","id":"placement-b","opaqueWorldBoundsPx":{"height":18,"width":14,"x"'
    ':17,"y":34},"primitiveId":"a","slotKey":"slot-b","stableOrderKey":{"anchorRo'
    'wMajor":11,"drawBandIndex":1,"ordinalLocal":3,"passIndex":1,"rank":2,"slotKe'
    'y":"slot-b"},"topLeftWorldPx":{"x":16,"y":32},"transform":{"flipX":true,"qua'
    'rterTurns":2},"visualSnapshotId":"border-snapshot-sha256:aaaaaaaaaaaaaaaaaaa'
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}]}';

const String borderBlueprintFingerprintGolden =
    'sha256:2ec2feae26e96747143d4c9478ef5f2cd0e59a827914fb3b2c1c4f0846260d22';
const String borderGeometryAndSeedFingerprintGolden =
    'sha256:b4d01a324035e02af317810d548283a86e0e63d06a9c21ba5de6c0ce65fde9aa';
const String borderParametersFingerprintGolden =
    'sha256:112c07cbbd852522556d3cf49dea7bae42ca740c43b16a0ce755dc1cf64870e9';
const String borderOverridesFingerprintGolden =
    'sha256:63ddf51388c17a60ae5d74bb22ed8c714d8fbd4c454537b00a751deb522589f2';
const String borderKeepOutRegionsFingerprintGolden =
    'sha256:47f2973b6303863624b5fe9e31e8af76cc95ccbf15b4138a3f98d4c8ff6b0d76';
const String borderMapContextFingerprintGolden =
    'sha256:4a0ea904799cd02f8be700539b18187e9e81bf04130403a0475362f6d56e1291';
const String borderVisualSnapshotsFingerprintGolden =
    'sha256:1cfa15a939a796362ed823785174edb3062d9ace179c7d22bd85a07f1388868e';
const String borderAggregateInputFingerprintGolden =
    'sha256:fac908adbe6f2887b0c59e21e3fcbc9eac3a2ae5e9824d3d68f9409e89469489';
const String borderOutputFingerprintGolden =
    'sha256:8a1df7be4f428b93af8ecea343cfdba1e35532343e82ee41ae67b52d0af69a77';
