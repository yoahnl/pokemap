import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def revise_qa(work, qa):
    sys.path.insert(0, str(work))
    canonical = load('revision_c708', work / 'c7_01_publier.py')
    content = load('content_c708', Path(__file__).with_name('c7_08_content.py'))
    data = work / 'revisites/c7-08'
    state = canonical.read(data / 'publication-qa.json')
    old = canonical.read(data / 'intention.json')
    if state['status'] not in {'IN_PROGRESS', 'APPLIED_POSTIMAGES_VERIFIED'} or state['pending'] is not None or Path(state['target']) != qa / 'project' or (data / 'publication-live.json').exists() or (data / 'qa-validation.json').exists():
        raise ValueError('Only an unambiguous owned QA preparation may be revised.')
    old_key = hashlib.sha256((data / 'intention.json').read_bytes()).hexdigest()
    if old_key != state['intentSha256']: raise ValueError('QA intention differs from its receipts.')
    revised = content.build(work)
    count = len(state['receipts'])
    if old['requests'][:count] != revised['requests'][:count]:
        raise ValueError('An applied request changed; preserve the fixture for review.')
    expected = {key: value for receipt in state['receipts'] for key, value in receipt['postimages'].items()}
    canonical.verify_files(qa / 'project', expected)
    for name, value in [('intention', old), ('publication-qa', state)]:
        archive = data / f'{name}-revision-{old_key[:16]}.json'
        if archive.exists(): raise ValueError('Preserve the prior revision archive.')
        canonical.save(archive, value)
    canonical.save(data / 'intention.json', revised)
    state['intentSha256'] = hashlib.sha256((data / 'intention.json').read_bytes()).hexdigest()
    state['status'] = 'IN_PROGRESS'
    canonical.save(data / 'publication-qa.json', state)
    canonical.save(data / f'qa-revision-{old_key[:16]}.json', {'status': 'UNAPPLIED_QA_TAIL_REVISED',
        'previousIntentSha256': old_key, 'intentSha256': state['intentSha256'], 'unchangedAppliedRequests': count,
        'verifiedPostimages': len(expected), 'sourceGameModified': False})
    print(json.dumps({'unchangedAppliedRequests': count, 'intentSha256': state['intentSha256']}))


def bind_capture_changes(canonical, changes, target):
    paths = {('catalogHead', 'catalog'): 'catalog/HEAD.json', ('itemCatalog', 'items'): 'data/pokemon/catalogs/items.json'}
    result = []
    for change in changes:
        key = (change['resource']['kind'], change['resource']['id'])
        if key not in paths: raise ValueError('Capture edit escaped its item catalog: ' + str(key))
        path = paths[key]
        original = (target / path).read_bytes()
        if change['beforeRevision'] != canonical.revision(path, original):
            raise ValueError('Capture catalog changed after planning.')
        result.append({**change, 'storageKey': path})
    if not any(row['storageKey'] == 'data/pokemon/catalogs/items.json' for row in result):
        raise ValueError('No item catalog mutation was planned.')
    return result


def publish(work, qa, live):
    sys.path.insert(0, str(work))
    canonical = load('canonical_c708', work / 'c7_01_publier.py')
    previous = load('scope_c708', work / 'c7_05_publier.py')
    data = work / 'revisites/c7-08'
    canonical.DATA, canonical.QA = data, qa
    target = work.parents[1] / 'jeu' if live else qa / 'project'
    intent_path = data / 'intention.json'
    intent = canonical.read(intent_path)
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    key = sha(intent_path)
    mode = 'live' if live else 'qa'
    receipt_path = data / f'publication-{mode}.json'
    state = canonical.read(receipt_path) if receipt_path.exists() else {
        'status': 'IN_PROGRESS', 'target': str(target), 'intentSha256': key, 'receipts': [], 'pending': None}
    if state['status'] != 'IN_PROGRESS' or state['intentSha256'] != key or state['pending'] is not None:
        raise ValueError('Review the existing applied or pending publication.')
    for name, checksum in intent['sourceWitnesses'].items():
        if sha(Path(name)) != checksum: raise ValueError('Changed source witness: ' + name)
    if live:
        gate = canonical.read(data / 'qa-validation.json')
        reviews = canonical.read(data / 'reviews.json')
        if gate['status'] != 'PASS' or gate['intentSha256'] != key or reviews.get('intentSha256') != key or reviews['spec']['status'] != 'PASS' or reviews['quality']['status'] != 'PASS':
            raise ValueError('Complete matching QA and independent reviews before live publication.')
        code_hashes = gate.get('codeSha256')
        if not isinstance(code_hashes, dict) or not code_hashes:
            raise ValueError('The QA gate must identify the qualified code.')
        repository = Path(__file__).resolve().parents[2]
        for relative, checksum in code_hashes.items():
            code = (repository / relative).resolve()
            if not code.is_relative_to(repository) or sha(code) != checksum:
                raise ValueError('Code changed after QA: ' + relative)
        for name, checksum in gate.get('externalHarnessSha256', {}).items():
            if sha(Path(name)) != checksum:
                raise ValueError('External harness changed after QA: ' + name)
    expected = dict(intent['guards']) if live else {}
    for receipt in state['receipts']: expected.update(receipt['postimages'])
    canonical.verify_files(target, expected)
    canonical.save(receipt_path, state)
    worker = canonical.Worker(target)
    try:
        for index, request in enumerate(intent['requests']):
            if index < len(state['receipts']): continue
            canonical.verify_files(target, expected)
            action, fields = canonical.canonical_request(request, target)
            if action == 'item.set_capture_effect':
                worker.call('workshop_prepare', {'projectHandle': worker.opened['projectHandle']})
            if action == 'asset.import_batch':
                entries = []
                for asset in fields['entries']:
                    staged = worker.call('stage_artifact', {'sourcePath': asset['sourcePath'], 'declaredMediaType': 'image/png'})
                    canonical.validate_staged_asset({**asset, 'sha256': sha(Path(asset['sourcePath']))}, staged)
                    entries.append({**{k: v for k, v in asset.items() if k != 'sourcePath'}, 'artifactHandle': staged['artifactHandle']})
                fields['entries'] = entries
            scope = worker.call('workshop_snapshot', {'projectHandle': worker.opened['projectHandle'], 'actionId': action, 'parameters': fields, 'includeDocuments': False})
            operation = f'hgss-c708-{mode}-{key[:16]}-{index}'
            planned = worker.call('plan', {'projectHandle': worker.opened['projectHandle'], 'request': {
                'requestId': operation, 'actionId': action, 'actionVersion': 1, 'workspaceHandle': worker.opened['workspaceHandle'],
                'parameters': fields, 'expectedRevision': scope['snapshotRevision'], 'idempotencyKey': operation,
                'dryRun': False, 'extensions': scope.get('planExtensions', {})}})
            plan = planned.get('plan', planned)
            plan_id = planned.get('planId', plan.get('planId'))
            changes = canonical.inventory(worker, plan)
            if action == 'item.set_capture_effect':
                bound = bind_capture_changes(canonical, changes, target)
            elif request['actionId'] in {'asset.import_batch', 'pokemon.catalog.entries.add'}:
                bound = canonical.bind_inventory(changes, request, target)
            else:
                bound = previous.bind(changes, request, target)
            state['pending'] = {'index': index, 'actionId': request['actionId'], 'operationId': operation + '-apply', 'planId': plan_id, 'changes': bound}
            canonical.save(receipt_path, state)
            args = {'projectHandle': worker.opened['projectHandle'], 'planId': plan_id, 'operationId': operation + '-apply'}
            if planned.get('requiresConfirmation') or plan.get('requiresConfirmation'):
                args['confirmationToken'] = worker.call('confirm', {'projectHandle': worker.opened['projectHandle'], 'planId': plan_id})['confirmationToken']
            receipt = worker.call('apply', args)['receipt']
            if receipt['status'] != 'applied': raise ValueError('The operation did not apply.')
            postimages = canonical.verify_postimages(target, bound)
            state['receipts'].append({**state['pending'], 'receipt': receipt, 'postimages': postimages})
            state['pending'] = None
            expected.update(postimages)
            canonical.save(receipt_path, state)
            print(json.dumps({'completed': index + 1, 'action': action}), flush=True)
        state['status'] = 'APPLIED_POSTIMAGES_VERIFIED'
        canonical.save(receipt_path, state)
    finally:
        worker.close()


def configure_capacity_fixture(work, qa):
    sys.path.insert(0, str(work))
    canonical = load('capacity_c708', work / 'c7_01_publier.py')
    canonical.DATA, canonical.QA = work / 'revisites/c7-08', qa
    worker = canonical.Worker(qa / 'bag-capacity-project')
    try:
        worker.call('workshop_prepare', {'projectHandle': worker.opened['projectHandle']})
        action = 'bag.capacity.set'
        parameters = {'pockets': {'items': {'maxQuantityPerItem': 99}, 'noigrumes': {'maxDistinctItems': 7, 'maxQuantityPerItem': 99}}}
        scope = worker.call('workshop_snapshot', {'projectHandle': worker.opened['projectHandle'], 'actionId': action, 'parameters': parameters, 'includeDocuments': False})
        planned = worker.call('plan', {'projectHandle': worker.opened['projectHandle'], 'request': {
            'requestId': 'hgss-c708-capacity-fixture', 'idempotencyKey': 'hgss-c708-capacity-fixture',
            'actionId': action, 'actionVersion': 1, 'workspaceHandle': worker.opened['workspaceHandle'],
            'parameters': parameters, 'expectedRevision': scope['snapshotRevision'], 'dryRun': False, 'extensions': scope.get('planExtensions', {})}})
        plan = planned.get('plan', planned)
        changes = canonical.inventory(worker, plan)
        if any(row['resource']['kind'] != 'catalogHead' for row in changes):
            raise ValueError('Capacity fixture escaped its metadata scope.')
        plan_id = planned.get('planId', plan.get('planId'))
        args = {'projectHandle': worker.opened['projectHandle'], 'planId': plan_id, 'operationId': 'hgss-c708-capacity-fixture-apply'}
        if planned.get('requiresConfirmation') or plan.get('requiresConfirmation'):
            args['confirmationToken'] = worker.call('confirm', {'projectHandle': worker.opened['projectHandle'], 'planId': plan_id})['confirmationToken']
        receipt = worker.call('apply', args)['receipt']
        if receipt['status'] != 'applied': raise ValueError('Capacity fixture not applied.')
        canonical.save(canonical.DATA / 'capacity-fixture.json', {'declaredFixture': True, 'sourceGameModified': False,
            'capacity': parameters, 'receipt': receipt})
    finally:
        worker.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('work', type=Path)
    parser.add_argument('qa', type=Path)
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--revise-qa', action='store_true')
    parser.add_argument('--capacity-fixture', action='store_true')
    args = parser.parse_args()
    if args.capacity_fixture:
        if args.live or args.revise_qa: raise ValueError('Capacity fixtures are QA only.')
        configure_capacity_fixture(args.work.resolve(), args.qa.resolve())
    elif args.revise_qa:
        if args.live: raise ValueError('Live revisions are forbidden.')
        revise_qa(args.work.resolve(), args.qa.resolve())
    else:
        publish(args.work.resolve(), args.qa.resolve(), args.live)
