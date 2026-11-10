import contextlib
import copy
import hashlib
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import update_plan


class UpdatePlanTests(unittest.TestCase):
    def setUp(self):
        qa = Path('/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109')
        qa.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix='dependency-rui004-test-', dir=qa)
        self.addCleanup(temporary.cleanup)
        self.repo = Path(temporary.name).resolve()
        self.root = self.repo / 'plan'
        self.root.mkdir()
        self.plan_path = self.root / 'ui-replacement-plan.json'
        self.proof_path = self.root / 'proof.txt'
        self.proof_path.write_text('Fixture proof for validator tests only.\n')
        self.proof = {'path': 'proof.txt', 'sha256': self.sha256(self.proof_path)}
        self.code_path = self.repo / 'source.py'
        self.code_path.write_text('value = 1\n')
        self.code = {'path': 'source.py', 'sha256': self.sha256(self.code_path)}
        constants = patch.multiple(update_plan, ROOT=self.root, REPO=self.repo, PLAN=self.plan_path)
        constants.start()
        self.addCleanup(constants.stop)
        self.lot = {
            'id': 'RUI-004', 'kind': 'evidence_framework', 'dependencies': [],
            'references': [], 'acceptance': ['Fixture criterion'],
            'requiredEvidence': [{'id': 'S01'}], 'minimumProofTiers': ['native_render'],
            'execution': {'status': 'review', 'attempts': []},
        }
        self.plan = {
            'lots': [self.lot], 'themes': [{'lotIds': ['RUI-004']}],
            'references': [], 'referenceBindings': [], 'verification': {},
            'stateModel': {
                'statuses': ['in_progress', 'review', 'rejected', 'accepted'],
                'transitions': {'in_progress': ['review', 'rejected'], 'review': ['accepted', 'rejected']},
            },
        }
        self.attempt = {
            'attemptId': 'fixture-attempt', 'at': '2026-11-10', 'requestedStatus': 'accepted',
            'implementer': 'fixture-implementer',
            'review': {'reviewer': 'fixture-reviewer', 'verdict': 'accepted', 'rationale': 'Fixture review'},
            'criterionResults': {'Fixture criterion': True},
            'commands': [{'command': 'fixture command', 'exitCode': 0, 'finishedAt': '2026-11-10', 'log': self.proof}],
            'evidenceFiles': [self.proof], 'codeFiles': [self.code],
        }

    @staticmethod
    def sha256(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def test_framework_requires_code_fingerprint(self):
        for code_files in (None, []):
            with self.subTest(code_files=code_files):
                attempt = copy.deepcopy(self.attempt)
                if code_files is None:
                    attempt.pop('codeFiles')
                else:
                    attempt['codeFiles'] = code_files
                with self.assertRaisesRegex(ValueError, 'Fingerprint du code absent'):
                    update_plan.check_attempt(self.plan, self.lot, attempt)

    def test_documentary_supplied_code_must_exist_and_match(self):
        for kind in ('preparation', 'design_baseline', 'evidence_framework'):
            for invalid in ({'path': 'missing.py', 'sha256': '0' * 64}, {'path': 'source.py', 'sha256': '0' * 64}):
                with self.subTest(kind=kind, code=invalid):
                    lot = dict(self.lot, kind=kind)
                    attempt = dict(self.attempt, codeFiles=[invalid])
                    with self.assertRaisesRegex(ValueError, 'Code absent|Preuve périmée'):
                        update_plan.check_attempt(self.plan, lot, attempt)

    def test_framework_valid_code_requires_no_native_profiles(self):
        update_plan.check_attempt(self.plan, self.lot, self.attempt)

    def test_preparation_and_design_baseline_keep_optional_code(self):
        attempt = copy.deepcopy(self.attempt)
        attempt.pop('codeFiles')
        for kind in ('preparation', 'design_baseline'):
            with self.subTest(kind=kind):
                update_plan.check_attempt(self.plan, dict(self.lot, kind=kind), attempt)

    def native_receipt(self):
        lot = dict(self.lot, id='RUI-005', kind='native_ui')
        plan = copy.deepcopy(self.plan)
        plan['lots'] = [lot]
        plan['references'] = [dict(self.proof, id='fixture-reference', designStatus='target')]
        attempt = copy.deepcopy(self.attempt)
        attempt['profiles'] = {}
        for profile in ('twoD', 'threeD'):
            binding = {
                'id': 'fixture-' + profile, 'lotId': lot['id'], 'profile': profile, 'stateId': 'S01',
                'referenceId': 'fixture-reference', 'approvedBy': 'fixture-reviewer',
                'approvedAt': '2026-11-10', 'viewport': {'width': 100, 'height': 100}, 'dpr': 1,
            }
            plan['referenceBindings'].append(binding)
            attempt['profiles'][profile] = {
                'functional': {case: {'passed': True, 'evidence': self.proof} for case in ('expected', 'negative', 'nonRegression')},
                'proofTiers': {'native_render': self.proof},
                'states': [{
                    'id': 'S01', 'targetBindingId': binding['id'], 'screenshot': self.proof,
                    'viewport': binding['viewport'], 'dpr': 1, 'measuredBy': 'fixture-reviewer',
                    'criticalIssues': [], 'score': dict(update_plan.WEIGHTS),
                    'metrics': {key: 0 for key in update_plan.METRICS},
                }],
            }
        return plan, lot, attempt

    def test_native_controls_and_95_threshold_are_preserved(self):
        plan, lot, attempt = self.native_receipt()
        attempt['profiles']['twoD']['states'][0]['score']['structure'] = 35
        update_plan.check_attempt(plan, lot, attempt)
        changes = {
            'codeAbsent': lambda p, a: a.pop('codeFiles'),
            'code': lambda p, a: a['codeFiles'][0].update(sha256='0' * 64),
            'profile': lambda p, a: a['profiles'].pop('threeD'),
            'state': lambda p, a: a['profiles']['twoD'].update(states=[]),
            'target': lambda p, a: p['referenceBindings'][0].update(approvedBy=None),
            'score94': lambda p, a: a['profiles']['twoD']['states'][0]['score'].update(structure=34),
            'critical': lambda p, a: a['profiles']['twoD']['states'][0].update(criticalIssues=['fixture']),
            'viewport': lambda p, a: a['profiles']['twoD']['states'][0].update(viewport={'width': 101, 'height': 100}),
            'metric': lambda p, a: a['profiles']['twoD']['states'][0]['metrics'].update(layoutMaxShiftLogicalPx=9),
        }
        for name, change in changes.items():
            with self.subTest(control=name):
                changed_plan, changed_attempt = copy.deepcopy(plan), copy.deepcopy(attempt)
                change(changed_plan, changed_attempt)
                with self.assertRaises(ValueError):
                    update_plan.check_attempt(changed_plan, lot, changed_attempt)

    def record(self, receipt):
        self.plan_path.write_text(json.dumps(self.plan, indent=2) + '\n')
        before = self.plan_path.read_bytes()
        receipt_path = self.root / 'receipt.json'
        receipt_path.write_text(json.dumps(receipt))
        arguments = ['update_plan.py', 'record', '--lot', self.lot['id'], '--receipt', str(receipt_path), '--emit-patch']
        with patch('sys.argv', arguments), patch.object(update_plan, 'patch', wraps=update_plan.patch) as emitted:
            with contextlib.redirect_stdout(io.StringIO()) as output:
                update_plan.main()
        self.assertEqual(self.plan_path.read_bytes(), before)
        self.assertTrue(output.getvalue().startswith('*** Begin Patch'))
        return json.loads(emitted.call_args.args[2])

    def test_record_preserves_refusal_when_next_attempt_is_accepted(self):
        refusal = {'attemptId': 'fixture-old-refusal', 'requestedStatus': 'rejected', 'blockReason': 'Fixture refusal'}
        self.lot['execution']['attempts'] = [refusal]
        after = self.record(self.attempt)
        execution = after['lots'][0]['execution']
        self.assertEqual(execution['status'], 'accepted')
        self.assertEqual(execution['attempts'], [refusal, self.attempt])

    def test_record_rejection_keeps_old_history(self):
        previous = {'attemptId': 'fixture-old-review', 'requestedStatus': 'review'}
        self.lot['execution']['attempts'] = [previous]
        rejection = dict(self.attempt, requestedStatus='rejected', blockReason='Fixture refusal')
        after = self.record(rejection)
        self.assertEqual(after['lots'][0]['execution']['status'], 'rejected')
        self.assertEqual(after['lots'][0]['execution']['attempts'], [previous, rejection])

    def test_record_refuses_duplicate_attempt_id(self):
        self.lot['execution']['attempts'] = [copy.deepcopy(self.attempt)]
        with self.assertRaisesRegex(ValueError, 'Tentative déjà enregistrée'):
            self.record(self.attempt)

    def test_record_refuses_missing_identity_and_forbidden_transition(self):
        for key in ('at', 'implementer'):
            with self.subTest(key=key):
                receipt = copy.deepcopy(self.attempt)
                receipt.pop(key)
                with self.assertRaisesRegex(ValueError, 'Date et implémenteur requis'):
                    self.record(receipt)
        self.lot['execution']['status'] = 'in_progress'
        with self.assertRaisesRegex(ValueError, 'Transition interdite'):
            self.record(self.attempt)

    def test_record_refuses_changed_framework_code_without_writing_plan(self):
        self.code_path.write_text('value = 2\n')
        with self.assertRaisesRegex(ValueError, 'Preuve périmée'):
            self.record(self.attempt)
        self.assertEqual(json.loads(self.plan_path.read_text()), self.plan)


if __name__ == '__main__':
    unittest.main()
