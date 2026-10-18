import copy
import json
import math
import re
from pathlib import PurePosixPath


def _keys(value, fields):
    if not isinstance(value, dict) or set(value) != set(fields):
        raise ValueError('Invalid source geometry policy fields')


def _strings(value):
    if not isinstance(value, list) or len(value) > 128 or any(
            not isinstance(item, str) or not item or len(item) > 256 for item in value):
        raise ValueError('Expected bounded source policy strings')


def validate_selector(value):
    if not isinstance(value, dict) or not set(value) <= {'exact', 'prefixes', 'contains', 'patterns'}:
        raise ValueError('Unknown material selector')
    for key, items in value.items():
        _strings(items)
        if key == 'patterns':
            for pattern in items:
                re.compile(pattern)
    return value


def matches(value, selector):
    name = value.lower()
    return (name in [item.lower() for item in selector.get('exact', [])] or
            any(name.startswith(item.lower()) for item in selector.get('prefixes', [])) or
            any(item.lower() in name for item in selector.get('contains', [])) or
            any(re.search(item, name) for item in selector.get('patterns', [])))


def _number(value, lower, upper):
    if type(value) not in (int, float) or not math.isfinite(value) or not lower <= value <= upper:
        raise ValueError('Invalid source geometry policy number')


def require_source_policy(value):
    _keys(value, {'schemaVersion', 'scene', 'ground', 'models', 'output'})
    if type(value['schemaVersion']) is not int or value['schemaVersion'] != 1:
        raise ValueError('Unsupported source geometry policy')
    scene, ground, models, output = (value[key] for key in ('scene', 'ground', 'models', 'output'))
    _keys(scene, {'unitsPerCell', 'objectNodePrefixes', 'terrainNodePrefixes', 'omittedMaterials'})
    _number(scene['unitsPerCell'], .001, 65536)
    _strings(scene['objectNodePrefixes'])
    _strings(scene['terrainNodePrefixes'])
    validate_selector(scene['omittedMaterials'])
    _keys(ground, {'excludedMaterials', 'floorRules', 'waterRules', 'minimumNormalY',
                   'maximumSourceHeight', 'sideOmissions', 'grassTerrain'})
    for field in ('excludedMaterials', 'sideOmissions', 'grassTerrain'):
        validate_selector(ground[field])
    _number(ground['minimumNormalY'], 0, 1)
    if ground['maximumSourceHeight'] is not None:
        _number(ground['maximumSourceHeight'], -65536, 65536)
    for field in ('floorRules', 'waterRules'):
        if not isinstance(ground[field], list) or len(ground[field]) > 128:
            raise ValueError('Source material rules exceed their budget')
        for rule in ground[field]:
            _keys(rule, {'kind', 'selector'} if field == 'floorRules' else {'selector', 'maxBoundsY'})
            validate_selector(rule['selector'])
            if field == 'floorRules' and rule['kind'] not in {'path', 'terrain'}:
                raise ValueError('Unknown floor kind')
            if field == 'waterRules' and rule['maxBoundsY'] is not None:
                _number(rule['maxBoundsY'], -65536, 65536)
    _keys(models, {'categories', 'omittedMaterials', 'rootMaterials', 'footprintGroups',
                  'nonBlockingMaterials'})
    for field in ('omittedMaterials', 'rootMaterials', 'footprintGroups', 'nonBlockingMaterials'):
        validate_selector(models[field])
    if not isinstance(models['categories'], list) or len(models['categories']) > 16:
        raise ValueError('Invalid model categories')
    for rule in models['categories']:
        _keys(rule, {'kind', 'selector'})
        if rule['kind'] not in {'forest', 'stairs', 'building', 'details'}:
            raise ValueError('Unknown source model category')
        validate_selector(rule['selector'])
    _keys(output, {'namespace', 'assetDirectory', 'tags', 'cliffSelectors'})
    if not isinstance(output['namespace'], str) or re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9_.-]{0,95}', output['namespace']) is None:
        raise ValueError('Invalid output namespace')
    relative = output['assetDirectory']
    if not isinstance(relative, str) or PurePosixPath(relative).is_absolute() or any(
            part in {'', '.', '..'} for part in relative.split('/')) or '\\' in relative or ':' in relative:
        raise ValueError('Invalid output asset directory')
    _strings(output['tags'])
    if not isinstance(output['cliffSelectors'], list) or len(output['cliffSelectors']) > 16:
        raise ValueError('Invalid cliff material selectors')
    for selector in output['cliffSelectors']:
        validate_selector(selector)
    return value


def read_source_policy(path):
    if path.stat().st_size > 2097152:
        raise ValueError('Source geometry policy exceeds 2 MiB')
    return require_source_policy(json.loads(path.read_text()))


def policy_for_asset(base, overrides):
    result = copy.deepcopy(base)
    if not isinstance(overrides, dict) or not set(overrides) <= {'scene', 'ground', 'models', 'output'}:
        raise ValueError('Invalid source policy override')
    for section, fields in overrides.items():
        if not isinstance(fields, dict) or not set(fields) <= set(result[section]):
            raise ValueError('Unknown source policy override fields')
        result[section].update(copy.deepcopy(fields))
    return require_source_policy(result)
