import contextlib
import copy
import hashlib
import io
import json
import struct
import subprocess
import tempfile
import unittest
import zlib
from pathlib import Path
from types import SimpleNamespace
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
        self.screenshot_path = self.root / 'host.png'
        def chunk(kind, data):
            return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
        self.screenshot_path.write_bytes(
            b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 6, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(b'\0\0\0\0\xff'))
            + chunk(b'IEND', b'')
        )
        self.screenshot = {'path': 'host.png', 'sha256': self.sha256(self.screenshot_path)}
        self.code_path = self.repo / 'source.py'
        self.code_path.write_text('value = 1\n')
        self.code = {'path': 'source.py', 'sha256': self.sha256(self.code_path)}
        constants = patch.multiple(update_plan, ROOT=self.root, REPO=self.repo, PLAN=self.plan_path)
        constants.start()
        self.addCleanup(constants.stop)
        self.requirements_check = update_plan.check_requirements
        requirements = patch.object(update_plan, 'check_requirements', lambda plan, lot=None: None)
        requirements.start()
        self.addCleanup(requirements.stop)
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
        for lot_id, kind in (('RUI-001', 'preparation'), ('RUI-003', 'design_baseline'), ('RUI-004', 'evidence_framework')):
            for invalid in ({'path': 'missing.py', 'sha256': '0' * 64}, {'path': 'source.py', 'sha256': '0' * 64}):
                with self.subTest(kind=kind, code=invalid):
                    lot = dict(self.lot, id=lot_id, kind=kind)
                    attempt = dict(self.attempt, codeFiles=[invalid])
                    with self.assertRaisesRegex(ValueError, 'Code absent|Preuve périmée'):
                        update_plan.check_attempt(self.plan, lot, attempt)

    def test_framework_valid_code_requires_no_native_profiles(self):
        update_plan.check_attempt(self.plan, self.lot, self.attempt)

    def test_preparation_and_design_baseline_keep_optional_code(self):
        attempt = copy.deepcopy(self.attempt)
        attempt.pop('codeFiles')
        for lot_id, kind in (('RUI-001', 'preparation'), ('RUI-003', 'design_baseline')):
            with self.subTest(kind=kind):
                update_plan.check_attempt(self.plan, dict(self.lot, id=lot_id, kind=kind), attempt)

    def native_receipt(self):
        lot = dict(self.lot, id='RUI-011', kind='native_ui')
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
            'duplicateState': lambda p, a: a['profiles']['twoD']['states'].append(copy.deepcopy(a['profiles']['twoD']['states'][0])),
            'unknownState': lambda p, a: a['profiles']['twoD']['states'].append({'id': 'unknown'}),
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

    def profile_specific_receipt(self):
        plan, lot, attempt = self.native_receipt()
        lot['id'] = 'RUI-013'
        lot['requiredEvidence'] = [
            {'id': 'S01', 'profiles': ['twoD', 'threeD']},
            {'id': 'S02', 'profiles': ['twoD']},
            {'id': 'S03', 'profiles': ['threeD']},
            {'id': 'S04', 'profiles': ['twoD', 'threeD']},
        ]
        for binding in plan['referenceBindings']:
            binding['lotId'] = lot['id']
        for profile, state_id in (('twoD', 'S02'), ('threeD', 'S03'), ('twoD', 'S04'), ('threeD', 'S04')):
            binding = copy.deepcopy(next(b for b in plan['referenceBindings'] if b['profile'] == profile))
            binding['id'] = 'fixture-' + profile + '-' + state_id
            binding['stateId'] = state_id
            plan['referenceBindings'].append(binding)
            state = copy.deepcopy(attempt['profiles'][profile]['states'][0])
            state['id'] = state_id
            state['targetBindingId'] = binding['id']
            attempt['profiles'][profile]['states'].append(state)
        plan['themes'] = [{'lotIds': [lot['id']]}]
        return plan, lot, attempt

    def test_native_receipt_checks_each_state_in_its_applicable_profiles(self):
        plan, lot, attempt = self.profile_specific_receipt()
        update_plan.check_attempt(plan, lot, attempt)
        for profile in ('twoD', 'threeD'):
            with self.subTest(profile=profile):
                missing = copy.deepcopy(attempt)
                missing['profiles'][profile]['states'].pop(1)
                with self.assertRaisesRegex(ValueError, 'États manquants'):
                    update_plan.check_attempt(plan, lot, missing)
                low = copy.deepcopy(attempt)
                low['profiles'][profile]['states'][1]['score']['structure'] = 34
                with self.assertRaisesRegex(ValueError, '95/100'):
                    update_plan.check_attempt(plan, lot, low)
        wrong_profile = copy.deepcopy(attempt)
        wrong_profile['profiles']['threeD']['states'].append(
            copy.deepcopy(attempt['profiles']['twoD']['states'][1])
        )
        with self.assertRaisesRegex(ValueError, 'États manquants'):
            update_plan.check_attempt(plan, lot, wrong_profile)

    def test_design_baseline_requires_applicable_profile_bindings(self):
        plan, lot, _ = self.profile_specific_receipt()
        baseline = dict(self.lot, id='RUI-003', kind='design_baseline')
        plan['lots'] = [baseline, lot]
        update_plan.check_attempt(plan, baseline, self.attempt)
        plan['referenceBindings'].pop()
        with self.assertRaisesRegex(ValueError, 'cibles approuvées manquantes'):
            update_plan.check_attempt(plan, baseline, self.attempt)

    def test_other_states_cannot_silently_drop_a_profile(self):
        plan, lot, attempt = self.native_receipt()
        lot['requiredEvidence'][0]['profiles'] = ['twoD']
        with self.assertRaisesRegex(ValueError, 'Profils requis'):
            update_plan.check_attempt(plan, lot, attempt)

    def test_non_applicable_bindings_and_malformed_profiles_are_refused(self):
        plan, lot, _ = self.profile_specific_receipt()
        update_plan.validate(plan)
        invalid_binding = copy.deepcopy(plan)
        binding = copy.deepcopy(next(b for b in invalid_binding['referenceBindings'] if b['stateId'] == 'S03'))
        binding.update(id='invalid-profile-binding', profile='twoD')
        invalid_binding['referenceBindings'].append(binding)
        with self.assertRaisesRegex(ValueError, 'état/profil inconnu'):
            update_plan.validate(invalid_binding)
        for profiles in ([], ['twoD', 'twoD'], ['twoD', 'threeD', 'fourD'], [[], []]):
            with self.subTest(profiles=profiles):
                malformed = copy.deepcopy(plan)
                malformed['lots'][0]['requiredEvidence'][0]['profiles'] = profiles
                with self.assertRaisesRegex(ValueError, 'Profils requis'):
                    update_plan.validate(malformed)

    def test_shell_profile_states_cannot_be_removed_from_the_plan(self):
        plan, _, _ = self.profile_specific_receipt()
        for removed in ('S01', 'S02', 'S03', 'S04'):
            with self.subTest(state=removed):
                changed = copy.deepcopy(plan)
                changed['lots'][0]['requiredEvidence'] = [
                    state for state in changed['lots'][0]['requiredEvidence'] if state['id'] != removed
                ]
                changed['referenceBindings'] = [
                    binding for binding in changed['referenceBindings'] if binding['stateId'] != removed
                ]
                with self.assertRaisesRegex(ValueError, 'États requis'):
                    update_plan.validate(changed)

    def test_full_contract_rejects_removing_or_replacing_a_required_state(self):
        plan = json.loads((Path(__file__).parent / 'ui-replacement-plan.json').read_text())
        lot = next(item for item in plan['lots'] if item['id'] == 'RUI-014')
        with patch.object(update_plan, 'check_requirements', self.requirements_check):
            update_plan.validate(plan, hashes=False)
            progress = copy.deepcopy(plan)
            progress['lots'][0]['execution']['progressNote'] = 'Avancement de test'
            update_plan.validate(progress, hashes=False)
            baseline = next(item for item in plan['lots'] if item['id'] == 'RUI-003')
            forged_lot = copy.deepcopy(baseline)
            forged_lot['acceptance'] = []
            with self.assertRaisesRegex(ValueError, 'lot différent du plan'):
                update_plan.check_attempt(plan, forged_lot, self.attempt)
            for edit in ('remove', 'replace', 'criteria', 'revision', 'swap', 'dependencies'):
                with self.subTest(edit=edit):
                    changed = copy.deepcopy(plan)
                    changed_lot = next(item for item in changed['lots'] if item['id'] == lot['id'])
                    state_list = changed_lot['requiredEvidence']
                    if edit == 'remove':
                        state_list.pop(0)
                    elif edit == 'replace':
                        state_list[0]['title'] = 'État remplacé'
                    elif edit == 'criteria':
                        changed_lot['acceptance'].pop()
                    elif edit == 'revision':
                        changed['requirementsRevision'] = 'révision-inconnue'
                    elif edit == 'dependencies':
                        changed_lot['dependencies'] = []
                    else:
                        state_list[0]['title'], state_list[1]['title'] = state_list[1]['title'], state_list[0]['title']
                    with self.assertRaisesRegex(ValueError, 'Contrat d’exigences'):
                        update_plan.validate(changed, hashes=False)
                    baseline = next(item for item in changed['lots'] if item['id'] == 'RUI-003')
                    with self.assertRaisesRegex(ValueError, 'Contrat d’exigences'):
                        update_plan.check_attempt(changed, baseline, self.attempt)

    def retirement_receipt(self):
        lot = dict(
            self.lot, id='RUI-005', kind='retirement',
            requiredEvidence=[{'id': 'S01', 'targetStatus': 'neutral_retirement_target_required', 'proofKind': 'technical_report'}],
            minimumProofTiers=['protected_behavior', 'native_neutral_host'],
        )
        plan = copy.deepcopy(self.plan)
        plan['lots'] = [lot]
        attempt = copy.deepcopy(self.attempt)
        attempt['profiles'] = {}
        for profile in ('twoD', 'threeD'):
            attempt['profiles'][profile] = {
                'functional': {case: {'passed': True, 'evidence': self.proof} for case in ('expected', 'negative', 'nonRegression')},
                'proofTiers': {'protected_behavior': self.proof, 'native_neutral_host': self.proof},
                'neutralHost': {
                    'screenshot': self.screenshot, 'viewport': {'width': 1, 'height': 1},
                    'dpr': 1, 'profile': profile, 'capturedBy': 'fixture-reviewer',
                    'observation': 'Hôte neutre observé',
                },
                'states': [{
                    'id': 'S01', 'passed': True, 'evidence': self.proof,
                    'checkedBy': 'fixture-reviewer', 'observation': 'État technique vérifié',
                    'criticalIssues': [],
                }],
            }
        return plan, lot, attempt

    def test_retirement_accepts_technical_evidence_without_mockup_target(self):
        plan, lot, attempt = self.retirement_receipt()
        update_plan.check_attempt(plan, lot, attempt)

    def test_retirement_rejects_missing_or_failed_evidence(self):
        plan, lot, attempt = self.retirement_receipt()
        changes = {
            'profile': lambda a: a['profiles'].pop('threeD'),
            'functional': lambda a: a['profiles']['twoD']['functional']['expected'].update(passed=False),
            'state': lambda a: a['profiles']['twoD'].update(states=[]),
            'duplicateState': lambda a: a['profiles']['twoD']['states'].append(copy.deepcopy(a['profiles']['twoD']['states'][0])),
            'unknownState': lambda a: a['profiles']['twoD']['states'].append({'id': 'unknown'}),
            'stateFailure': lambda a: a['profiles']['twoD']['states'][0].update(passed=False),
            'stateEvidence': lambda a: a['profiles']['twoD']['states'][0].pop('evidence'),
            'stateObservation': lambda a: a['profiles']['twoD']['states'][0].update(observation=''),
            'stateReviewer': lambda a: a['profiles']['twoD']['states'][0].update(checkedBy=''),
            'stateCritical': lambda a: a['profiles']['twoD']['states'][0].update(criticalIssues=['Défaut']),
            'stateCriticalAbsent': lambda a: a['profiles']['twoD']['states'][0].pop('criticalIssues'),
            'host': lambda a: a['profiles']['twoD'].pop('neutralHost'),
            'hostImage': lambda a: a['profiles']['twoD']['neutralHost']['screenshot'].update(sha256='0' * 64),
            'hostViewport': lambda a: a['profiles']['twoD']['neutralHost'].update(viewport={'width': 0, 'height': 100}),
            'hostProfile': lambda a: a['profiles']['twoD']['neutralHost'].update(profile='threeD'),
            'hostDpr': lambda a: a['profiles']['twoD']['neutralHost'].update(dpr=float('nan')),
            'hostAuthor': lambda a: a['profiles']['twoD']['neutralHost'].update(capturedBy=''),
            'tier': lambda a: a['profiles']['twoD']['proofTiers'].pop('protected_behavior'),
            'fingerprint': lambda a: a['codeFiles'][0].update(sha256='0' * 64),
            'review': lambda a: a['review'].update(reviewer=a['implementer']),
            'command': lambda a: a['commands'][0].update(exitCode=1),
        }
        for name, change in changes.items():
            with self.subTest(control=name):
                changed = copy.deepcopy(attempt)
                change(changed)
                with self.assertRaises(ValueError):
                    update_plan.check_attempt(plan, lot, changed)

    def test_retirement_rejects_a_text_file_disguised_as_a_capture(self):
        plan, lot, attempt = self.retirement_receipt()
        self.screenshot_path.write_text('not a screenshot')
        attempt['profiles']['twoD']['neutralHost']['screenshot']['sha256'] = self.sha256(self.screenshot_path)
        with self.assertRaisesRegex(ValueError, 'Capture native non image'):
            update_plan.check_attempt(plan, lot, attempt)

    def test_retirement_rejects_incomplete_or_wrong_size_capture(self):
        plan, lot, attempt = self.retirement_receipt()
        attempt['profiles']['twoD']['neutralHost']['viewport']['width'] = 100
        with self.assertRaisesRegex(ValueError, 'dimensions'):
            update_plan.check_attempt(plan, lot, attempt)
        self.screenshot_path.write_bytes(b'\x89PNG\r\n\x1a\n')
        attempt['profiles']['twoD']['neutralHost']['screenshot']['sha256'] = self.sha256(self.screenshot_path)
        with self.assertRaisesRegex(ValueError, 'Capture native non image'):
            update_plan.check_attempt(plan, lot, attempt)

    def test_retirement_accepts_full_jpeg_and_rejects_a_truncated_jpeg(self):
        plan, lot, attempt = self.retirement_receipt()
        source = Path(__file__).resolve().parent / 'proofs/t01-execution/native-neutral-host.jpg'
        jpeg = self.root / 'host.jpg'
        content = source.read_bytes()
        jpeg.write_bytes(content)
        for profile in ('twoD', 'threeD'):
            attempt['profiles'][profile]['neutralHost'].update(
                screenshot={'path': 'host.jpg', 'sha256': self.sha256(jpeg)},
                viewport={'width': 1000, 'height': 752},
            )
        update_plan.check_attempt(plan, lot, attempt)
        jpeg.write_bytes(content[:50] + b'\xff\xd9')
        attempt['profiles']['twoD']['neutralHost']['screenshot']['sha256'] = self.sha256(jpeg)
        with self.assertRaisesRegex(ValueError, 'Capture native non image'):
            update_plan.check_attempt(plan, lot, attempt)

    def test_retirement_rejects_undecodable_pixels_in_png_and_jpeg(self):
        plan, lot, attempt = self.retirement_receipt()
        def chunk(kind, data):
            return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
        invalid_png = (b'\x89PNG\r\n\x1a\n'
                       + chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 6, 0, 0, 0))
                       + chunk(b'IDAT', b'not-a-zlib-stream') + chunk(b'IEND', b''))
        invalid_jpeg = (b'\xff\xd8\xff\xc0\x00\x11\x08\x00\x01\x00\x01\x03'
                        b'\x01\x11\x00\x02\x11\x00\x03\x11\x00'
                        b'\xff\xda\x00\x0c\x03\x01\x00\x02\x11\x03\x11\x00\x3f\x00\x00\xff\xd9')
        for name, content in (('bad.png', invalid_png), ('bad.jpg', invalid_jpeg)):
            with self.subTest(image=name):
                path = self.root / name
                path.write_bytes(content)
                attempt['profiles']['twoD']['neutralHost']['screenshot'] = {'path': name, 'sha256': self.sha256(path)}
                with self.assertRaisesRegex(ValueError, 'décoder|invalide'):
                    update_plan.check_attempt(plan, lot, attempt)

    def test_a_rebuilt_ui_cannot_choose_the_retirement_contract(self):
        plan, lot, attempt = self.retirement_receipt()
        lot['id'] = 'RUI-011'
        with self.assertRaises(ValueError):
            update_plan.check_attempt(plan, lot, attempt)
        lot['kind'] = 'native_ui'
        with self.assertRaises(ValueError):
            update_plan.check_attempt(plan, lot, attempt)
        lot['kind'] = 'preparation'
        with self.assertRaises(ValueError):
            update_plan.check_attempt(plan, lot, attempt)

    def test_retirement_capture_required_for_native_host_state(self):
        plan, lot, attempt = self.retirement_receipt()
        lot.update(id='RUI-006', requiredEvidence=[{
            'id': 'S01', 'targetStatus': 'neutral_retirement_target_required',
            'proofKind': 'native_capture',
        }])
        for profile in ('twoD', 'threeD'):
            attempt['profiles'][profile]['states'][0]['capture'] = copy.deepcopy(attempt['profiles'][profile]['neutralHost'])
        update_plan.check_attempt(plan, lot, attempt)
        for change in (
            lambda s: s.pop('capture'),
            lambda s: s['capture'].update(profile='threeD'),
            lambda s: s['capture'].update(dpr=0),
        ):
            changed = copy.deepcopy(attempt)
            change(changed['profiles']['twoD']['states'][0])
            with self.assertRaises(ValueError):
                update_plan.check_attempt(plan, lot, changed)

    def test_retirement_gate_requires_a_passing_g0_report(self):
        plan, lot, attempt = self.retirement_receipt()
        lot.update(id='RUI-010', kind='retirement_gate', requiredEvidence=[{
            'id': 'S01', 'targetStatus': 'neutral_retirement_target_required',
            'proofKind': 'native_capture',
        }])
        for profile in ('twoD', 'threeD'):
            attempt['profiles'][profile]['states'][0]['capture'] = copy.deepcopy(attempt['profiles'][profile]['neutralHost'])
        inventory_path = self.root / 'inventory.json'
        inventory_path.write_text(json.dumps({'entries': [{'path': 'old.dart', 'decision': 'retired_ui'}]}))
        plan['inventoryPath'] = 'inventory.json'
        report_path = self.root / 'g0.json'
        report = {
            'schemaVersion': 1, 'gate': 'G0', 'proofTier': 'static_retirement',
            'passed': True, 'roots': ['apps/avelune_studio/lib/main.dart'],
            'contexts': [{'name': 'studio', 'roots': ['apps/avelune_studio/lib/main.dart'], 'reachableSources': 1}],
            'exceptions': [],
            'counts': {'inventoryEntries': 1, 'reachableSources': 1,
                       'studioSourcesInspected': 1, 'violations': 0},
            'violations': [],
        }
        studio = self.repo / 'apps/avelune_studio'
        (studio / '.dart_tool').mkdir(parents=True)
        (studio / '.dart_tool/package_config.json').write_text(json.dumps({
            'configVersion': 2, 'packages': [{'name': 'avelune_studio', 'rootUri': '../', 'packageUri': 'lib/'}],
        }))
        (studio / 'tools').mkdir()
        for name in ('t01_check_g0.dart', 't01_retirement_gate.dart', 't01_dependency_graph.dart', 't01_dart_lexing.dart', 't01_consumer_entries.dart', 't01_validate_screenshot.dart'):
            path = studio / 'tools' / name
            path.write_text('fixture')
            attempt['codeFiles'].append({'path': str(path.relative_to(self.repo)), 'sha256': self.sha256(path)})
        (self.root / 't01-technical-exceptions.json').write_text('{}')
        report_path.write_text(json.dumps(report))
        attempt['retirementGate'] = {
            'reachableOldWidgets': 0, 'oldRoutes': 0, 'legacyFallbacks': 0,
            'report': {'path': 'g0.json', 'sha256': self.sha256(report_path)},
            'inventorySha256': self.sha256(inventory_path),
            'allowlistSha256': self.sha256(self.root / 't01-technical-exceptions.json'),
        }
        with patch.object(update_plan, 'g0_dart_executable', return_value='/fixture/dart'), patch('subprocess.run', return_value=SimpleNamespace(returncode=0, stdout=json.dumps(report))) as runner:
            update_plan.check_attempt(plan, lot, attempt)
            self.assertEqual(runner.call_args.kwargs['cwd'], studio)
            self.assertIn(str(self.repo), runner.call_args.args[0])
            for change in (
                lambda r: r.update(passed=False),
                lambda r: r['counts'].update(violations=1),
                lambda r: r['counts'].update(inventoryEntries=0),
                lambda r: r.update(violations=[{'kind': 'physical'}]),
                lambda r: r.update(roots=[]),
                lambda r: r.update(roots=['another.dart']),
                lambda r: r.update(contexts=[]),
            ):
                changed = copy.deepcopy(report)
                change(changed)
                report_path.write_text(json.dumps(changed))
                attempt['retirementGate']['report']['sha256'] = self.sha256(report_path)
                with self.assertRaises(ValueError):
                    update_plan.check_attempt(plan, lot, attempt)
            report_path.write_text(json.dumps(report))
            attempt['retirementGate']['report']['sha256'] = self.sha256(report_path)
            runner.return_value = SimpleNamespace(returncode=1, stdout=json.dumps(dict(report, passed=False)))
            with self.assertRaises(ValueError):
                update_plan.check_attempt(plan, lot, attempt)
            runner.return_value = SimpleNamespace(returncode=0, stdout='invalid json')
            with self.assertRaises(ValueError):
                update_plan.check_attempt(plan, lot, attempt)
            runner.return_value = SimpleNamespace(returncode=0, stdout=json.dumps(report))
            with patch.object(update_plan, 'g0_dart_executable', return_value=None):
                with self.assertRaises(ValueError):
                    update_plan.check_attempt(plan, lot, attempt)
            runner.side_effect = subprocess.TimeoutExpired('dart', 55)
            with self.assertRaises(ValueError):
                update_plan.check_attempt(plan, lot, attempt)
            runner.side_effect = None
            config = studio / '.dart_tool/package_config.json'
            correct_config = config.read_text()
            config.write_text(json.dumps({'packages': [{'name': 'avelune_studio', 'rootUri': 'file:///wrong-checkout/'}]}))
            with self.assertRaisesRegex(ValueError, 'hors checkout'):
                update_plan.check_attempt(plan, lot, attempt)
            config.write_text(json.dumps({'packages': [{'name': 'avelune_studio', 'rootUri': '../', 'packageUri': '../../wrong/'}]}))
            with self.assertRaisesRegex(ValueError, 'hors checkout'):
                update_plan.check_attempt(plan, lot, attempt)
            config.write_text(json.dumps({'packages': [
                {'name': 'avelune_studio', 'rootUri': '../', 'packageUri': 'lib/'},
                {'name': 'map_render_3d', 'rootUri': 'file:///wrong-checkout/', 'packageUri': 'lib/'},
            ]}))
            with self.assertRaisesRegex(ValueError, 'hors checkout'):
                update_plan.check_attempt(plan, lot, attempt)
            config.write_text(correct_config)
            omitted = copy.deepcopy(attempt)
            omitted['codeFiles'] = [item for item in omitted['codeFiles'] if not item['path'].endswith('t01_dependency_graph.dart')]
            with self.assertRaises(ValueError):
                update_plan.check_attempt(plan, lot, omitted)
            (studio / 'tools/t01_dependency_graph.dart').write_text('changed')
            with self.assertRaises(ValueError):
                update_plan.check_attempt(plan, lot, attempt)
            (studio / 'tools/t01_dependency_graph.dart').write_text('fixture')
            inventory_path.write_text(json.dumps({'entries': [{'path': 'other.dart', 'decision': 'retired_ui'}]}))
            with self.assertRaises(ValueError):
                update_plan.check_attempt(plan, lot, attempt)
            inventory_path.write_text(json.dumps({'entries': [{'path': 'old.dart', 'decision': 'classification requise avant retrait'}]}))
            with self.assertRaises(ValueError):
                update_plan.check_attempt(plan, lot, attempt)

    def test_design_baseline_excludes_retirement_but_not_rebuilt_ui(self):
        retirement_plan, retirement, _ = self.retirement_receipt()
        native_plan, native, _ = self.native_receipt()
        baseline = dict(self.lot, id='RUI-003', kind='design_baseline')
        plan = dict(retirement_plan, lots=[baseline, retirement, native],
                    referenceBindings=native_plan['referenceBindings'])
        update_plan.check_attempt(plan, baseline, self.attempt)
        plan['referenceBindings'].pop()
        with self.assertRaisesRegex(ValueError, 'cibles approuvées manquantes'):
            update_plan.check_attempt(plan, baseline, self.attempt)

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
