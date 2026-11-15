const dialogueLocalizationSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['format', 'sourceLocale', 'units'],
  'properties': {
    'format': {'const': 1},
    'sourceLocale': {'type': 'string', 'minLength': 2},
    'units': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['id', 'binding', 'kind', 'source', 'translations'],
        'properties': {
          'id': {'type': 'string', 'minLength': 1},
          'binding': {'type': 'string', 'minLength': 1},
          'kind': {
            'enum': ['line', 'narration', 'choice']
          },
          'source': {'type': 'string', 'minLength': 1},
          'translations': {
            'type': 'object',
            'additionalProperties': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['text', 'source'],
              'properties': {
                'text': {'type': 'string', 'minLength': 1},
                'source': {'type': 'string', 'minLength': 1},
              },
            }
          },
        },
      }
    },
  },
};
