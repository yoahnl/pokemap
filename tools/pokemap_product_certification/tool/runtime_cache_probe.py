import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import urllib.parse
import urllib.request


def field(value, name):
    for item in reversed(value.get('fields', [])):
        if item['decl']['name'] == name:
            return item['value']
    raise ValueError(f'Missing VM field: {name}')


def scalar(value):
    if value.get('type') == 'Sentinel' or value.get('valueAsStringIsTruncated'):
        raise ValueError('Collected or truncated VM value')
    kind = value.get('kind')
    if kind == 'Null':
        return None
    raw = value.get('valueAsString')
    if kind == 'Bool' and raw in ('true', 'false'):
        return raw == 'true'
    if kind == 'Int':
        return int(raw)
    if kind == 'String' and raw is not None:
        return raw
    raise ValueError(f'Expected scalar, got {kind}')


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError('VM service redirects are refused')


class VmReader:
    def __init__(self, base, isolate_id=None):
        parsed = urllib.parse.urlsplit(base)
        if (parsed.scheme != 'http' or parsed.hostname not in ('127.0.0.1', 'localhost', '::1')
                or parsed.username or parsed.password or parsed.query or parsed.fragment):
            raise ValueError('Use an adb-forwarded loopback HTTP VM service URL')
        self.base = base.rstrip('/') + '/'
        self.isolate = isolate_id

    def rpc(self, method, **params):
        if method not in ('getVM', 'getIsolate', 'getObject', 'getInstances'):
            raise ValueError(f'Non-observational RPC refused: {method}')
        url = self.base + method + '?' + urllib.parse.urlencode(params)
        opener = urllib.request.build_opener(NoRedirect, urllib.request.ProxyHandler({}))
        with opener.open(url, timeout=15) as response:
            raw = response.read(16 * 1024 * 1024 + 1)
        if len(raw) > 16 * 1024 * 1024:
            raise ValueError('VM response exceeded observation limit')
        document = json.loads(raw)
        if 'error' in document:
            raise ValueError(document['error'])
        result = document['result']
        if result.get('type') == 'Sentinel':
            raise ValueError('VM object expired; repeat the observation')
        return result

    def obj(self, ref):
        return self.rpc('getObject', isolateId=self.isolate, objectId=ref['id'], count=1024)

    def value(self, ref):
        if ref.get('valueAsStringIsTruncated'):
            ref = self.obj(ref)
        return scalar(ref)

    def entries(self, ref):
        value = self.obj(ref)
        if value.get('kind') == 'PlainInstance' and value.get('length') == 1:
            value = self.obj(field(value, '_map'))
        entries = value.get('associations', [])
        if value.get('kind') != 'Map' or value.get('length') != len(entries):
            raise ValueError('Incomplete VM map observation')
        return entries

    def instances(self, libraries, suffix, name):
        library = next(item for item in libraries if item['uri'].endswith('/' + suffix))
        cls = next(item for item in self.obj(library)['classes'] if item['name'] == name)
        result = self.rpc('getInstances', isolateId=self.isolate, objectId=cls['id'], limit=32)
        if result['totalCount'] > 32 or len(result['instances']) != result['totalCount']:
            raise ValueError('Too many live instances for a bounded observation')
        return [self.obj(item) for item in result['instances']]

    def settled_stamp(self, game):
        bundle = self.obj(field(game, '_bundle'))
        budget = self.obj(field(bundle, 'resourceBudget'))
        counts = {name: scalar(field(budget, '_' + name)) for name in ('residentBytes', 'transientBytes', 'activeDecodes')}
        pending = self.obj(field(budget, '_pending'))['length']
        if scalar(field(game, '_isRemoved')) or counts['transientBytes'] or counts['activeDecodes'] or pending:
            raise ValueError('Runtime has not settled; repeat the observation')
        player = self.obj(field(self.obj(field(game, '_player')), '_state'))
        pos = self.obj(field(player, 'pos'))
        return {
            'position': {name: scalar(field(pos, name)) for name in ('x', 'y')},
            'gameIdentity': game['identityHashCode'],
            'activeMapId': scalar(field(game, '_activeMapId')),
            'revision': scalar(field(game, '_gameStateRevision')),
            'loadedMapIds': [scalar(e['key']) for e in self.entries(field(game, '_loadedMapsById'))],
            **counts, 'pendingDecodes': pending,
        }

    def snapshot(self):
        started_at = datetime.now(timezone.utc).isoformat()
        vm = self.rpc('getVM')
        main = [item for item in vm['isolates'] if item['name'] == 'main']
        if self.isolate is None:
            if len(main) != 1:
                raise ValueError('Specify --isolate-id for a multi-engine process: ' + str([item['id'] for item in main]))
            self.isolate = main[0]['id']
        if self.isolate not in [item['id'] for item in main]:
            raise ValueError('Requested main isolate is no longer live')
        libraries = self.rpc('getIsolate', isolateId=self.isolate)['libraries']
        games = self.instances(libraries, 'playable_map_game.dart', 'PlayableMapGame')
        games = [game for game in games if not scalar(field(game, '_isRemoved'))]
        if len(games) != 1:
            raise ValueError(f'Expected one active game, found {len(games)}')
        game = games[0]
        before = self.settled_stamp(game)
        budget = self.obj(field(self.obj(field(game, '_bundle')), 'resourceBudget'))
        profile = self.obj(field(budget, 'profile'))
        cache = self.obj(field(game, '_tilesetImageCache'))
        images = []
        for entry in self.entries(field(cache, '_completed')):
            key = self.obj(entry['key'])
            image = self.obj(entry['value'])
            images.append({
                'path': self.value(field(key, 'normalizedAbsolutePath')),
                'vmId': image['id'],
                'identityHashCode': image['identityHashCode'],
                **{name: scalar(field(image, name)) for name in ('width', 'height', '_isDisposed')},
            })
        catalogs = []
        for catalog in self.instances(libraries, 'runtime_project_catalog.dart', 'RuntimeProjectCatalog'):
            if scalar(field(catalog, '_disposed')):
                continue
            reader_ref = field(catalog, '_reader')
            if reader_ref.get('kind') == 'Null':
                raise ValueError('Portable catalogue reader required')
            reader = self.obj(reader_ref)
            catalogs.append({
                'path': self.value(field(catalog, 'projectFilePath')),
                'vmId': reader['id'],
                'cachedBytes': scalar(field(reader, '_cachedBytes')),
                'admittedBytes': scalar(field(reader, '_bytes')),
                'objects': [{
                    'sha256': scalar(entry['key']),
                    'futureVmId': entry['value']['id'],
                } for entry in self.entries(field(reader, '_cache'))],
            })
        state = self.obj(field(game, '_gameState'))
        player_state = self.obj(field(self.obj(field(game, '_player')), '_state'))
        position = self.obj(field(player_state, 'pos'))
        facts = self.obj(field(state, 'narrativeFactRuntimeState'))
        result = {
            'schemaVersion': 1,
            'observationStartedAt': started_at,
            'atomic': False,
            'playerPosition': {name: scalar(field(position, name)) for name in ('x', 'y')},
            'facts': {scalar(e['key']): scalar(field(self.obj(e['value']), '_value')) for e in self.entries(field(facts, 'valuesByFactId'))},
            'gameIdentity': game['identityHashCode'],
            'pid': vm['pid'],
            'isolateId': self.isolate,
            'gameVmId': game['id'],
            'activeMapId': scalar(field(game, '_activeMapId')),
            'loadedMapIds': [scalar(e['key']) for e in self.entries(field(game, '_loadedMapsById'))],
            'bundleMapIds': [scalar(e['key']) for e in self.entries(field(game, '_runtimeBundleByMapId'))],
            'budget': {name: scalar(field(budget, '_' + name)) for name in (
                'residentBytes', 'transientBytes', 'activeDecodes', 'peakBytes', 'peakConcurrentDecodes')},
            'pendingDecodes': self.obj(field(budget, '_pending'))['length'],
            'limits': {name: scalar(field(profile, name)) for name in (
                'maximumResidentBytes', 'maximumTransientBytes', 'maximumConcurrentDecodes', 'maximumEncodedBytes')},
            'images': images,
            'catalogs': catalogs,
            'processRssBytes': vm.get('_currentRSS'),
            'processMaxRssBytes': vm.get('_maxRSS'),
        }
        after = self.settled_stamp(self.obj(game))
        if before != after:
            raise ValueError('Runtime changed during observation; repeat it')
        result['stableGuard'] = before
        result['observationFinishedAt'] = datetime.now(timezone.utc).isoformat()
        return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--service-url', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--isolate-id')
    options = parser.parse_args()
    if options.output.exists():
        parser.error('Observation destination already exists')
    result = VmReader(options.service_url, options.isolate_id).snapshot()
    with options.output.open('x') as output:
        json.dump(result, output, indent=2)
        output.write('\n')
    print(json.dumps({key: result[key] for key in (
        'activeMapId', 'playerPosition', 'facts', 'loadedMapIds', 'bundleMapIds', 'budget', 'pendingDecodes', 'limits')}))


if __name__ == '__main__':
    main()
