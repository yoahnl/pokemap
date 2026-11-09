import importlib.util
import hashlib
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, patch


class CalendarContentTest(unittest.TestCase):
    def test_encounter_uses_civil_day_and_durable_non_item_identity(self):
        path = Path(__file__).with_name('c7_08_content.py')
        spec = importlib.util.spec_from_file_location('calendar_content', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        scene, event, rules = module.lapras_content()
        nodes = {node['id']: node for node in scene['graph']['nodes']}
        self.assertEqual(nodes['weekday']['payload']['conditionSource']['weekday'], 'friday')
        policy = nodes['battle']['payload']['periodicEncounter']
        self.assertEqual(policy['consumeOnOutcomes'], ['victory', 'captured', 'fled'])
        self.assertNotIn('defeat', policy['consumeOnOutcomes'])
        self.assertEqual(nodes['battle']['payload']['battleTemplateId'], 'hgss-revisite-lokhlass-vendredi')
        self.assertEqual(event['definition']['reusePolicy'], 'reusable')
        self.assertEqual({rule['source']['kind'] for rule in rules}, {'civilWeekday', 'periodicRewardAvailable'})
        reference = next(rule['source']['rewardReference'] for rule in rules if rule['source']['kind'] == 'periodicRewardAvailable')
        self.assertEqual(reference, {'schemaVersion': 1, 'sceneId': scene['id'], 'nodeId': 'battle', 'rewardId': policy['rewardId']})

    def test_reward_fact_is_only_reached_after_successful_delivery(self):
        path = Path(__file__).with_name('c7_08_content.py')
        spec = importlib.util.spec_from_file_location('calendar_content', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        scene, event, rules = module.vanessa_content()
        nodes = {node['id']: node for node in scene['graph']['nodes']}
        self.assertEqual(nodes['gift']['payload']['interactiveCommand']['itemId'], 'poison-barb')
        edges = scene['graph']['edges']
        incoming = [edge for edge in edges if edge['toNodeId'] == 'record']
        self.assertEqual([(edge['fromNodeId'], edge['fromPortId']) for edge in incoming], [('gift', 'received')])
        self.assertEqual(next(edge['toNodeId'] for edge in edges if edge['fromNodeId'] == 'gift' and edge['fromPortId'] == 'bagFull'), 'end')
        self.assertEqual(event['definition']['reusePolicy'], 'reusable')
        self.assertTrue(all(rule['source']['weekday'] == 'friday' for rule in rules))

    def check_publication_gate(self, *, stale_review=False, stale_code=False, stale_harness=False):
        path = Path(__file__).with_name('c7_08_publish.py')
        spec = importlib.util.spec_from_file_location('calendar_publish', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        qa = Path('/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/c7-08')
        with tempfile.TemporaryDirectory(prefix='publication-gate-', dir=qa) as temporary:
            work = Path(temporary) / 'creation/work'
            data = work / 'revisites/c7-08'
            data.mkdir(parents=True)
            intent_path = data / 'intention.json'
            intent_path.write_text('{}')
            key = hashlib.sha256(intent_path.read_bytes()).hexdigest()
            code = Path(__file__).with_name('c7_08_content.py')
            digest = '0' * 64 if stale_code else hashlib.sha256(code.read_bytes()).hexdigest()
            documents = {
                'intention.json': {'sourceWitnesses': {}, 'guards': {}, 'requests': []},
                'qa-validation.json': {'status': 'PASS', 'intentSha256': key,
                    'externalHarnessSha256': {str(code.resolve()): '0' * 64 if stale_harness else hashlib.sha256(code.read_bytes()).hexdigest()},
                    'codeSha256': {'tools/heartgold/c7_08_content.py': digest}},
                'reviews.json': {'intentSha256': 'stale' if stale_review else key,
                    'spec': {'status': 'PASS'}, 'quality': {'status': 'PASS'}},
            }
            worker = Mock()
            canonical = SimpleNamespace(read=lambda file: documents[file.name],
                save=Mock(), verify_files=Mock(), Worker=Mock(return_value=worker))
            with patch.object(module, 'load', return_value=canonical):
                if stale_review or stale_code or stale_harness:
                    with self.assertRaises(ValueError):
                        module.publish(work, qa, True)
                    canonical.save.assert_not_called()
                    canonical.Worker.assert_not_called()
                else:
                    module.publish(work, qa, True)
                    canonical.Worker.assert_called_once()
                    worker.close.assert_called_once()

    def test_publication_accepts_matching_review_and_code(self):
        self.check_publication_gate()

    def test_publication_rejects_a_review_from_another_intention(self):
        self.check_publication_gate(stale_review=True)

    def test_publication_rejects_code_changed_after_qa(self):
        self.check_publication_gate(stale_code=True)

    def test_publication_rejects_an_external_harness_changed_after_qa(self):
        self.check_publication_gate(stale_harness=True)


if __name__ == '__main__':
    unittest.main()
