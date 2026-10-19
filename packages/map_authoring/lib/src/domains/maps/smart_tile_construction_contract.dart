const adaptiveSmartTileConstructionContract = <String, Object?>{
  'field': 'pattern.construction',
  'minimumCatalogFormatVersion': 8,
  'dimension': '2d',
  'fixedCrossSection': 'expand_whole',
  'partialPeriods': 'reject',
  'rectangleOrigin': 'normalized_selection',
  'phaseX': 0,
  'phaseY': 0,
  'transforms': 'authored_sources_only',
  'strokeBoundsField': 'constructionBounds',
  'eraseAndResize': 'preserve_original_bounds_and_phase',
  'mapClipping': 'reject_before_mutation',
  'line': 'one_variable_axis_only',
  'rectangle': 'fixed_ends_and_whole_periods',
  'maximumExpandedStrokeCells': 4096,
  'sourceAxis': 'leading_repeat_trailing',
  'fixedAxis': 'absent_axis_object',
  'schema': {
    'type': 'object',
    'additionalProperties': false,
    'properties': {
      'x': {
        'anyOf': [
          {'type': 'null'},
          adaptiveSmartTileRepeatAxisSchema
        ]
      },
      'y': {
        'anyOf': [
          {'type': 'null'},
          adaptiveSmartTileRepeatAxisSchema
        ]
      },
    },
    'anyOf': [
      {
        'required': ['x'],
        'properties': {
          'x': {'type': 'object'}
        }
      },
      {
        'required': ['y'],
        'properties': {
          'y': {'type': 'object'}
        }
      },
    ],
  },
};

const adaptiveSmartTileRepeatAxisSchema = <String, Object?>{
  'type': 'object',
  'additionalProperties': false,
  'required': ['repeatStart', 'repeatLength'],
  'properties': {
    'repeatStart': {'type': 'integer', 'minimum': 0, 'maximum': 64},
    'repeatLength': {'type': 'integer', 'minimum': 1, 'maximum': 64},
    'minimumRepeats': {
      'type': 'integer',
      'minimum': 0,
      'maximum': 65536,
      'default': 1,
    },
    'maximumRepeats': {
      'type': ['integer', 'null'],
      'minimum': 0,
      'maximum': 65536,
    },
  },
};

const smartTilePatternClippingContract = <String, Object?>{
  'field': 'pattern.clippingPolicy',
  'minimumCatalogFormatVersion': 8,
  'values': ['clip', 'reject'],
  'default': 'clip',
  'schema': {'type': 'string', 'enum': ['clip', 'reject'], 'default': 'clip'},
  'appliesTo': 'anchored_stamp_envelope',
  'includesSparseHoles': true,
  'validation': 'before_any_cell_or_batch_mutation',
  'rejectionCode': 'smart_tile.pattern.stamp_out_of_bounds',
  'existingStrokeErasureAndPhase': 'preserved',
};
