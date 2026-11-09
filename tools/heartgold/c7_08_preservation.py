import hashlib
import importlib.util
import json
import sys
from pathlib import Path


def main(work, verify):
    sys.path.insert(0, str(work))
    import c7_01_publier as canonical
    import c7_02_publier as previous
    source = work.parents[1] / 'jeu'
    data = work / 'revisites/c7-08'
    save = work.parent / 'ecorcia-chapitre7/preuves/parcours-complet/final-porte-bois.save.json'
    snapshot = data / 'preservation-before.json'
    if not verify:
        if snapshot.exists(): raise ValueError('Preserve the initial source inventory.')
        files = previous.stable_inventory(source)
        canonical.save(snapshot, {'files': files, 'assets': previous.asset_record_digests(source),
            'items': canonical.read(source / 'data/pokemon/catalogs/items.json'),
            'authenticSaveSha256': previous.sha(save)})
        print(json.dumps({'frozenFiles': len(files), 'authenticSaveSha256': previous.sha(save)}))
        return
    before = canonical.read(snapshot)
    publication = canonical.read(data / 'publication-live.json')
    if publication['status'] != 'APPLIED_POSTIMAGES_VERIFIED' or publication['pending'] is not None:
        raise ValueError('Live publication is incomplete.')
    expected = {key: value for receipt in publication['receipts'] for key, value in receipt['postimages'].items()}
    canonical.verify_files(source, expected)
    after = previous.stable_inventory(source)
    changed = [key for key, value in before['files'].items() if after.get(key) != value]
    unexpected = [key for key in changed if key not in expected]
    if unexpected: raise ValueError('Unexpected old source changes: ' + str(unexpected))
    assets = previous.asset_record_digests(source)
    if any(assets.get(key) != value for key, value in before['assets'].items()):
        raise ValueError('A prior asset record changed.')
    if previous.sha(save) != before['authenticSaveSha256']:
        raise ValueError('The authentic save changed.')
    items = {row['id']: row for row in canonical.read(source / 'data/pokemon/catalogs/items.json')['entries']}
    for row in before['items']['entries']:
        candidate = items[row['id']]
        if row['id'] in {'poke-ball', 'great-ball', 'premier-ball'}:
            original, current = dict(row), dict(candidate)
            left, right = dict(original.pop('capture')), dict(current.pop('capture'))
            kinds = right.pop('allowedEncounterKinds')
            old_kinds = left.pop('allowedEncounterKinds')
            if original != current or left != right or set(kinds) != {*old_kinds, 'special'}:
                raise ValueError('A capture definition changed outside its declared context extension.')
        elif candidate != row: raise ValueError('An unrelated item definition changed.')
    result = {'status': 'PASS', 'priorFilesChecked': len(before['files']), 'priorAssetsPreserved': len(before['assets']),
        'changedOldFiles': changed, 'unexpectedChanges': [], 'canonicalPostimages': len(expected),
        'authenticSaveSha256': before['authenticSaveSha256'], 'authenticSaveUnchanged': True,
        'newItem': 'poison-barb', 'captureContextsExtendedOnly': ['poke-ball', 'great-ball', 'premier-ball']}
    canonical.save(data / 'preservation-final.json', result)
    print(json.dumps(result))


if __name__ == '__main__':
    main(Path(sys.argv[1]).resolve(), '--verify' in sys.argv)
