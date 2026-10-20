import importlib.util
from datetime import datetime
import json
from pathlib import Path
import unittest
from unittest import mock
import urllib.parse

spec = importlib.util.spec_from_file_location(
    'probe', Path(__file__).parents[1] / 'tool' / 'runtime_cache_probe.py')
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)


class ProbeTest(unittest.TestCase):
    def test_only_loopback_http_service_is_accepted(self):
        for url in ['https://example.com/', 'http://example.com/',
                    'file:///tmp/vm', 'http://127.0.0.1:1@evil.test/']:
            with self.assertRaises(ValueError):
                probe.VmReader(url)
        self.assertEqual(probe.VmReader('http://127.0.0.1:1234/token/').base,
                         'http://127.0.0.1:1234/token/')

    def test_rpc_whitelist_cannot_evaluate_or_mutate(self):
        reader = probe.VmReader('http://127.0.0.1:1/')
        for method in ['evaluate', 'invoke', 'resume', 'setFlag', 'getAllocationProfile']:
            with self.assertRaises(ValueError):
                reader.rpc(method)

    def test_fields_require_presence_and_preserve_false_zero(self):
        value = {'fields': [
            {'decl': {'name': '_isDisposed'}, 'value': {'kind': 'Bool', 'valueAsString': 'false'}},
            {'decl': {'name': '_cachedBytes'}, 'value': {'kind': 'Int', 'valueAsString': '0'}}]}
        self.assertFalse(probe.scalar(probe.field(value, '_isDisposed')))
        self.assertEqual(probe.scalar(probe.field(value, '_cachedBytes')), 0)
        with self.assertRaises(ValueError):
            probe.field(value, 'absent')

    def test_truncation_and_collected_objects_are_explicit_failures(self):
        with self.assertRaises(ValueError):
            probe.scalar({'kind': 'String', 'valueAsString': 'prefix', 'valueAsStringIsTruncated': True})
        with self.assertRaises(ValueError):
            probe.scalar({'type': 'Sentinel', 'kind': 'Collected'})

    def test_map_snapshot_refuses_partial_associations(self):
        class Fake(probe.VmReader):
            def obj(self, ref):
                return {'kind': 'Map', 'length': 2, 'associations': [
                    {'key': {'kind': 'String', 'valueAsString': 'a'}, 'value': {'kind': 'Int', 'valueAsString': '1'}}]}
        with self.assertRaises(ValueError):
            Fake('http://127.0.0.1:1/').entries({'id': 'objects/1'})


def _vm_value(kind, value):
    return {'kind': kind, 'valueAsString': str(value)}


def _vm_object(object_id, **fields):
    return {'id': object_id, 'fields': [
        {'decl': {'name': name}, 'value': value}
        for name, value in fields.items()]}


def _snapshot_reader():
    ref = lambda name: {'id': name}
    objects = {
        'game': _vm_object('game',
            _isRemoved=_vm_value('Bool', 'false'),
            _activeMapId=_vm_value('String', 'map/a'),
            _gameStateRevision=_vm_value('Int', 7),
            _bundle=ref('bundle'), _player=ref('player'),
            _tilesetImageCache=ref('cache'), _gameState=ref('state'),
            _loadedMapsById=ref('loaded'), _runtimeBundleByMapId=ref('bundles')),
        'bundle': _vm_object('bundle', resourceBudget=ref('budget')),
        'budget': _vm_object('budget',
            _residentBytes=_vm_value('Int', 64),
            _transientBytes=_vm_value('Int', 0),
            _activeDecodes=_vm_value('Int', 0),
            _peakBytes=_vm_value('Int', 64),
            _peakConcurrentDecodes=_vm_value('Int', 1),
            _pending=ref('pending'), profile=ref('profile')),
        'pending': {'length': 0},
        'profile': _vm_object('profile', **{
            name: _vm_value('Int', value) for name, value in {
                'maximumResidentBytes': 128, 'maximumTransientBytes': 256,
                'maximumConcurrentDecodes': 2, 'maximumEncodedBytes': 512}.items()}),
        'cache': _vm_object('cache', _completed=ref('images')),
        'state': _vm_object('state', playerPosition=ref('logical-position'),
                            narrativeFactRuntimeState=ref('facts')),
        'player': _vm_object('player', _state=ref('player-state')),
        'player-state': _vm_object('player-state', pos=ref('live-position')),
        'live-position': _vm_object('live-position', x=_vm_value('Int', 2),
                                    y=_vm_value('Int', 3)),
        'logical-position': _vm_object('logical-position', x=_vm_value('Int', 99),
                                       y=_vm_value('Int', 99)),
        'facts': _vm_object('facts', valuesByFactId=ref('fact-values')),
        'fact': _vm_object('fact', _value=_vm_value('Bool', 'false')),
    }
    objects['game']['identityHashCode'] = 101
    maps = {
        'loaded': [{'key': _vm_value('String', 'map/a'), 'value': ref('game')}],
        'bundles': [{'key': _vm_value('String', 'map/a'), 'value': ref('bundle')}],
        'images': [],
        'fact-values': [{'key': _vm_value('String', 'story.started'),
                         'value': ref('fact')}],
    }
    reader = probe.VmReader('http://127.0.0.1:1/')
    reader.rpc = mock.Mock(side_effect=lambda method, **params: {
        'getVM': {'pid': 123, 'isolates': [{'name': 'main', 'id': 'isolates/main'}]},
        'getIsolate': {'libraries': []}}[method])
    reader.instances = mock.Mock(side_effect=lambda libraries, suffix, name:
                                 [objects['game']] if name == 'PlayableMapGame' else [])
    reader.obj = mock.Mock(side_effect=lambda value: objects[value['id']])
    reader.entries = mock.Mock(side_effect=lambda value: maps[value['id']])
    return reader, objects


class ProbeTransportTest(unittest.TestCase):
    def response(self, body):
        response = mock.MagicMock()
        response.__enter__.return_value = response
        response.read.return_value = body
        return response

    def test_rpc_refuses_more_than_16_mib_before_decoding(self):
        response = self.response(b' ' * (16 * 1024 * 1024 + 1))
        with mock.patch.object(probe.urllib.request, 'build_opener') as factory:
            factory.return_value.open.return_value = response
            with mock.patch.object(probe.json, 'loads') as decode:
                with self.assertRaises(ValueError):
                    probe.VmReader('http://127.0.0.1:1/').rpc('getVM')
                decode.assert_not_called()
        response.read.assert_called_once_with(16 * 1024 * 1024 + 1)

    def test_rpc_accepts_exactly_16_mib_with_a_bounded_read(self):
        document = b'{"result":{}}'
        response = self.response(document + b' ' * (16 * 1024 * 1024 - len(document)))
        with mock.patch.object(probe.urllib.request, 'build_opener') as factory:
            factory.return_value.open.return_value = response
            self.assertEqual(probe.VmReader('http://127.0.0.1:1/').rpc('getVM'), {})
        response.read.assert_called_once_with(16 * 1024 * 1024 + 1)

    def test_rpc_errors_and_collected_results_are_explicit_failures(self):
        for document in [
            {'error': {'code': 113, 'message': 'Isolate has exited'}},
            {'result': {'type': 'Sentinel', 'kind': 'Collected'}},
        ]:
            with self.subTest(document=document):
                response = self.response(json.dumps(document).encode())
                with mock.patch.object(probe.urllib.request, 'build_opener') as factory:
                    factory.return_value.open.return_value = response
                    with self.assertRaises(ValueError):
                        probe.VmReader('http://127.0.0.1:1/').rpc('getVM')

    def test_get_object_requests_1024_items_with_the_selected_isolate(self):
        response = self.response(b'{"result":{"kind":"Map","length":0}}')
        with mock.patch.object(probe.urllib.request, 'build_opener') as factory:
            factory.return_value.open.return_value = response
            reader = probe.VmReader('http://127.0.0.1:1234/token/', 'isolates/main')
            self.assertEqual(reader.obj({'id': 'objects/1'})['kind'], 'Map')
            args, kwargs = factory.return_value.open.call_args
            parsed = urllib.parse.urlsplit(args[0])
            self.assertEqual(parsed.path, '/token/getObject')
            self.assertEqual(urllib.parse.parse_qs(parsed.query), {
                'isolateId': ['isolates/main'], 'objectId': ['objects/1'],
                'count': ['1024']})
            self.assertEqual(kwargs, {'timeout': 15})

    def test_rpc_disables_proxies_and_uses_a_redirect_refusing_handler(self):
        with mock.patch.object(probe.urllib.request, 'build_opener') as factory:
            factory.return_value.open.return_value = self.response(b'{"result":{}}')
            probe.VmReader('http://127.0.0.1:1/').rpc('getVM')
            redirect, proxy = factory.call_args.args
            self.assertIs(redirect, probe.NoRedirect)
            self.assertIsInstance(proxy, probe.urllib.request.ProxyHandler)
            self.assertEqual(proxy.proxies, {})

    def test_redirect_handler_refuses_external_and_loopback_redirects(self):
        for destination in ['http://example.com/', 'http://127.0.0.1:2/']:
            with self.subTest(destination=destination):
                with self.assertRaises(ValueError):
                    probe.NoRedirect().redirect_request(
                        None, None, 302, 'Found', {}, destination)

    def test_truncated_strings_are_expanded_before_reading_the_value(self):
        reader = probe.VmReader('http://127.0.0.1:1/')
        reader.obj = mock.Mock(return_value=_vm_value('String', 'complete value'))
        ref = {'id': 'objects/string', 'kind': 'String', 'valueAsString': 'prefix',
               'valueAsStringIsTruncated': True}
        self.assertEqual(reader.value(ref), 'complete value')
        reader.obj.assert_called_once_with(ref)
        reader.obj.return_value = ref
        with self.assertRaises(ValueError):
            reader.value(ref)


class ProbeObjectsTest(unittest.TestCase):
    def instances_reader(self, total, instances):
        library = {'id': 'libraries/1', 'uri': 'package:runtime/playable_map_game.dart'}
        reader = probe.VmReader('http://127.0.0.1:1/', 'isolates/main')
        reader.obj = mock.Mock(side_effect=lambda ref: {
            'classes': [{'id': 'classes/game', 'name': 'PlayableMapGame'}]}
            if ref['id'] == library['id'] else ref)
        reader.rpc = mock.Mock(return_value={'totalCount': total, 'instances': instances})
        return reader, [library]

    def test_instances_refuse_over_limit_and_partial_enumerations(self):
        for total, refs in [(33, [{'id': str(i)} for i in range(32)]),
                            (2, [{'id': 'objects/1'}]),
                            (0, [{'id': 'objects/unexpected'}])]:
            with self.subTest(total=total, returned=len(refs)):
                reader, libraries = self.instances_reader(total, refs)
                with self.assertRaises(ValueError):
                    reader.instances(libraries, 'playable_map_game.dart', 'PlayableMapGame')
                reader.rpc.assert_called_once_with('getInstances',
                    isolateId='isolates/main', objectId='classes/game', limit=32)
                self.assertEqual(reader.obj.call_count, 1)

    def test_instances_accept_empty_and_complete_boundary_enumerations(self):
        for total in [0, 32]:
            with self.subTest(total=total):
                refs = [{'id': f'objects/{index}'} for index in range(total)]
                reader, libraries = self.instances_reader(total, refs)
                self.assertEqual(reader.instances(
                    libraries, 'playable_map_game.dart', 'PlayableMapGame'), refs)
                self.assertEqual(reader.obj.call_count, total + 1)

    def test_map_wrappers_are_unwrapped_and_still_require_complete_associations(self):
        association = {'key': _vm_value('String', 'key'), 'value': _vm_value('Int', 0)}
        for length in [1, 2]:
            with self.subTest(length=length):
                reader = probe.VmReader('http://127.0.0.1:1/')
                wrapper = _vm_object('objects/wrapper', _map={'id': 'objects/map'})
                wrapper.update({'kind': 'PlainInstance', 'length': 1})
                reader.obj = mock.Mock(side_effect=[wrapper, {
                    'kind': 'Map', 'length': length, 'associations': [association]}])
                if length == 1:
                    self.assertEqual(reader.entries({'id': 'objects/wrapper'}), [association])
                else:
                    with self.assertRaises(ValueError):
                        reader.entries({'id': 'objects/wrapper'})
                self.assertEqual(reader.obj.call_args_list, [
                    mock.call({'id': 'objects/wrapper'}), mock.call({'id': 'objects/map'})])

    def test_field_prefers_the_last_most_derived_declaration(self):
        value = {'fields': [
            {'decl': {'name': '_state'}, 'value': {'id': 'objects/base'}},
            {'decl': {'name': '_state'}, 'value': {'id': 'objects/derived'}}]}
        self.assertEqual(probe.field(value, '_state'), {'id': 'objects/derived'})


class ProbeSnapshotTest(unittest.TestCase):
    def test_settled_stamp_keeps_idle_counts_identity_and_live_position(self):
        reader, objects = _snapshot_reader()
        self.assertEqual(reader.settled_stamp(objects['game']), {
            'position': {'x': 2, 'y': 3}, 'gameIdentity': 101, 'activeMapId': 'map/a',
            'revision': 7, 'loadedMapIds': ['map/a'], 'residentBytes': 64,
            'transientBytes': 0, 'activeDecodes': 0, 'pendingDecodes': 0})

    def test_settled_stamp_refuses_removed_games_and_in_flight_work(self):
        for changed in ['removed', 'transient', 'decodes', 'pending']:
            with self.subTest(changed=changed):
                reader, objects = _snapshot_reader()
                if changed == 'removed':
                    probe.field(objects['game'], '_isRemoved')['valueAsString'] = 'true'
                elif changed == 'pending':
                    objects['pending']['length'] = 1
                else:
                    name = '_transientBytes' if changed == 'transient' else '_activeDecodes'
                    probe.field(objects['budget'], name)['valueAsString'] = '1'
                with self.assertRaises(ValueError):
                    reader.settled_stamp(objects['game'])

    def test_snapshot_reports_a_non_atomic_interval_and_live_actor_position(self):
        reader, objects = _snapshot_reader()
        result = reader.snapshot()
        self.assertIs(result['atomic'], False)
        self.assertEqual(result['playerPosition'], {'x': 2, 'y': 3})
        self.assertEqual(result['facts'], {'story.started': False})
        self.assertEqual(result['stableGuard'], reader.settled_stamp(objects['game']))
        self.assertEqual(result['isolateId'], 'isolates/main')
        started = datetime.fromisoformat(result['observationStartedAt'])
        finished = datetime.fromisoformat(result['observationFinishedAt'])
        self.assertIsNotNone(started.utcoffset())
        self.assertLessEqual(started, finished)

    def test_snapshot_refuses_changes_between_its_guards(self):
        for name, changed in {
            'position': {'x': 3, 'y': 3}, 'gameIdentity': 102,
            'activeMapId': 'map/b', 'revision': 8,
            'loadedMapIds': ['map/a', 'map/b'], 'residentBytes': 65,
        }.items():
            with self.subTest(changed=name):
                reader, objects = _snapshot_reader()
                before = reader.settled_stamp(objects['game'])
                reader.settled_stamp = mock.Mock(side_effect=[before, {**before, name: changed}])
                with self.assertRaises(ValueError):
                    reader.snapshot()
                self.assertEqual(reader.settled_stamp.call_count, 2)


if __name__ == '__main__':
    unittest.main()
