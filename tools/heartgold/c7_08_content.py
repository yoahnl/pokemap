import argparse
import copy
import hashlib
import json
import re
import uuid
from pathlib import Path


LAPRAS_SCENE = 'hgss-ch7-c708-lokhlass'
LAPRAS_REWARD = 'hgss-ch7-lokhlass-vendredi'
VANESSA_SCENE = 'hgss-ch7-c708-vanessa'
VANESSA_FACT = 'fact_hgss_vanessa_pic_venin_recu'
SIBLING_FACT = 'fact_hgss_fratrie_jours_rencontres'


def node(identity, kind, **payload):
    return {'id': identity, 'kind': kind, **({'payload': {'kind': kind, **payload}} if payload else {})}


def scene(identity, label, nodes, edges):
    return {'id': identity, 'name': label, 'tags': ['hgss', 'c708'], 'graph': {
        'startNodeId': 'start', 'nodes': [node('start', 'start'), node('end', 'end', outcomePolicy='progression'), *nodes],
        'edges': [{'id': f'e{i}', 'fromNodeId': a, 'fromPortId': port, 'toNodeId': b, 'kind': kind}
                  for i, (a, port, b, kind) in enumerate(edges)]}}


def event(identity, map_id, entity_id):
    value = uuid.uuid5(uuid.NAMESPACE_URL, 'heartgold/chapitre7/' + identity)
    value = uuid.UUID(bytes=value.bytes[:6] + bytes([(value.bytes[6] & 15) | 112]) + value.bytes[7:])
    return {'state': 'configured', 'enabled': True, 'definition': {
        'id': 'evt_' + str(value), 'name': identity, 'source': {'mapId': map_id, 'kind': 'entityInteract', 'entityId': entity_id},
        'conditions': [], 'sceneId': identity, 'reusePolicy': 'reusable', 'priority': 100, 'order': 7080}}


def weekday_source():
    return {'sourceKind': 'civilWeekday', 'sourceId': 'civilWeekday', 'operator': 'isTrue', 'weekday': 'friday'}


def weekday_rule(identity, map_id, entity_id):
    return {'id': identity, 'label': identity.removeprefix('world_rule_').replace('_', ' '), 'enabled': True,
        'source': {'kind': 'civilWeekday', 'sourceId': 'civilWeekday', 'predicate': 'isFalse', 'weekday': 'friday'},
        'target': {'kind': 'mapEntity', 'mapId': map_id, 'entityId': entity_id},
        'effect': {'kind': 'entityHidden'}, 'priority': 500, 'tags': ['hgss', 'c708']}


def lapras_content():
    reference = {'schemaVersion': 1, 'sceneId': LAPRAS_SCENE, 'nodeId': 'battle', 'rewardId': LAPRAS_REWARD}
    nodes = [node('weekday', 'condition', conditionSource=weekday_source()),
        node('available', 'condition', conditionSource={'sourceKind': 'periodicRewardAvailable',
            'sourceId': LAPRAS_REWARD, 'operator': 'isTrue', 'rewardReference': reference}),
        node('battle', 'battle', battleKind='wild', battleTemplateId='hgss-revisite-lokhlass-vendredi',
            npcEntityId='ch7-lokhlass-154-3', defeatRecovery='returnToRecoveryPoint',
            declaredOutcomes=['victory', 'captured', 'runaway', 'defeat'],
            periodicEncounter={'schemaVersion': 1, 'rewardId': LAPRAS_REWARD, 'label': 'Lokhlass du vendredi',
                'consumeOnOutcomes': ['victory', 'captured', 'fled']})]
    edges = [('start', 'completed', 'weekday', 'defaultFlow'), ('weekday', 'true', 'available', 'conditionTrue'),
        ('weekday', 'false', 'end', 'conditionFalse'), ('available', 'true', 'battle', 'conditionTrue'),
        ('available', 'false', 'end', 'conditionFalse')]
    edges += [('battle', outcome, 'end', 'battleVictory' if outcome == 'victory' else 'battleDefeat' if outcome == 'defeat' else 'branchOutcome')
              for outcome in ['victory', 'captured', 'runaway', 'defeat']]
    rule = weekday_rule('world_rule_c708_lokhlass_vendredi', 'caves-jumelles-sous-sol2', 'ch7-lokhlass-154-3')
    consumed = copy.deepcopy(rule)
    consumed.update(id='world_rule_c708_lokhlass_consomme', label='c708 lokhlass consomme')
    consumed['source'] = {'kind': 'periodicRewardAvailable', 'sourceId': LAPRAS_REWARD,
        'predicate': 'isFalse', 'rewardReference': reference}
    return scene(LAPRAS_SCENE, 'Lokhlass — rencontre du vendredi', nodes, edges), event(LAPRAS_SCENE, 'caves-jumelles-sous-sol2', 'ch7-lokhlass-154-3'), [rule, consumed]


def vanessa_content():
    nodes = [node('weekday', 'condition', conditionSource=weekday_source()),
        node('owned', 'condition', conditionSource={'sourceKind': 'fact', 'sourceId': VANESSA_FACT, 'operator': 'isTrue'}),
        node('greeting', 'yarnDialogue', dialogueId='hgss-c708-vanessa-16', yarnNodeName='Start', expectedOutcomes=[]),
        node('gift', 'action', interactiveCommand={'kind': 'giveItem', 'itemId': 'poison-barb', 'quantity': 1}),
        node('record', 'action', consequence={'kind': 'setFact', 'factId': VANESSA_FACT, 'value': True}),
        node('count', 'action', consequence={'kind': 'adjustIntegerFact', 'factId': SIBLING_FACT, 'delta': 1, 'minimum': 0, 'maximum': 7}),
        node('thanks', 'yarnDialogue', dialogueId='hgss-c708-vanessa-17', yarnNodeName='Start', expectedOutcomes=[]),
        node('repeat', 'yarnDialogue', dialogueId='hgss-c708-vanessa-18', yarnNodeName='Start', expectedOutcomes=[])]
    edges = [('start', 'completed', 'weekday', 'defaultFlow'), ('weekday', 'false', 'end', 'conditionFalse'),
        ('weekday', 'true', 'owned', 'conditionTrue'), ('owned', 'true', 'repeat', 'conditionTrue'),
        ('owned', 'false', 'greeting', 'conditionFalse'), ('greeting', 'completed', 'gift', 'defaultFlow'),
        ('gift', 'received', 'record', 'actionCompleted'), ('gift', 'bagFull', 'end', 'actionCompleted'),
        ('record', 'completed', 'count', 'actionCompleted'), ('count', 'completed', 'thanks', 'actionCompleted'),
        ('thanks', 'completed', 'end', 'defaultFlow'), ('repeat', 'completed', 'end', 'defaultFlow')]
    return scene(VANESSA_SCENE, 'Vanessa — le vendredi', nodes, edges), event(VANESSA_SCENE, 'route-32', 'ch7-36-14'), [weekday_rule('world_rule_c708_vanessa_vendredi', 'route-32', 'ch7-36-14')]


def build(work):
    data = work / 'revisites/c7-08'
    before = json.loads((data / 'readback-before.json').read_text())
    preparation = json.loads((work / 'revisites/preparation.json').read_text())['lapras']
    reference = work.parents[1] / 'references/heartgold-fr'
    messages = {row['id']: row['text'] for row in json.loads((reference / 'dialogues/banques/0752.json').read_text())['messages']}
    project = before['project']
    for identity in [LAPRAS_SCENE, VANESSA_SCENE]:
        if any(row['id'] == identity for row in project['scenes']):
            raise ValueError('Preserve the existing scene: ' + identity)
    dialogues = []
    for number in [16, 17, 18]:
        text = re.sub(r'\\[nrf]', '\n', messages[number]).strip()
        if re.search(r'\{[A-Z_]', text): raise ValueError('Unresolved source message token')
        dialogues.append({'entry': {'id': f'hgss-c708-vanessa-{number}', 'name': f'Vanessa {number}',
            'relativePath': f'dialogues/johto/ecorcia/chapitre7/c708-vanessa-{number}.yarn', 'declaredOutcomes': []},
            'source': 'title: Start\n---\n' + text + '\n===\n'})
    asset_id = 'asset-hgss-c708-lokhlass'
    atlas_path = 'assets/personnages/johto/ecorcia-chapitre7/lokhlass/atlas-native.png'
    atlas = preparation['sourceSprite']['atlases'][0]
    character_id = preparation['candidateEntity']['npc']['characterId']
    animations = []
    for direction, start in [('south', 4), ('west', 8), ('east', 12), ('north', 0)]:
        frames = [{'source': {key: frame[key] for key in ['x', 'y', 'width', 'height']}, 'durationMs': 250}
                  for frame in atlas['frames'][start:start + 4]]
        animations.append({'state': 'idle', 'direction': direction, 'sourceAssetId': asset_id, 'frames': frames, 'loop': True})
    lapras_scene, lapras_event, lapras_rules = lapras_content()
    vanessa_scene, vanessa_event, vanessa_rules = vanessa_content()
    requests = [
        {'actionId': 'asset.import_batch', 'parameters': {'entries': [
            {'sourcePath': str(data / 'assets/lapras.png'), 'assetId': asset_id, 'logicalPath': atlas_path, 'tags': ['hgss', 'c708', 'rom-exact'], 'usages': ['character_sprite']},
            {'sourcePath': str(data / 'assets/poison-barb.png'), 'assetId': 'item-icon-poison-barb', 'logicalPath': 'data/pokemon/assets/items/poison-barb.png', 'tags': ['hgss', 'c708', 'rom-exact'], 'usages': ['image']}]}},
        {'actionId': 'tileset.upsert', 'parameters': {'tileset': {'id': character_id, 'name': 'Lokhlass — atlas natif',
            'relativePath': atlas_path, 'source': {'kind': 'regular_atlas', 'assetId': asset_id, 'pixelWidth': 256, 'pixelHeight': 64,
                'tileWidth': 32, 'tileHeight': 32, 'tileProperties': []}, 'scope': 'global', 'sortOrder': 0,
            'isWorldTileset': False, 'elementGroups': [], 'paletteEntries': []}}},
        {'actionId': 'campaign.character.upsert', 'parameters': {'value': {'id': character_id, 'name': 'Lokhlass',
            'tilesetId': character_id, 'frameWidth': 1, 'frameHeight': 1, 'animations': animations, 'tags': ['hgss', 'c708'], 'sortOrder': 0}}},
        copy.deepcopy(preparation['candidateRequests'][0]),
        {'actionId': 'pokemon.catalog.entries.add', 'parameters': {'relativePath': 'data/pokemon/catalogs/items.json', 'entries': [{
            'id': 'poison-barb', 'displayName': 'Pic Venin', 'aliases': ['poison_barb'], 'pocketId': 'items',
            'description': 'Objet à tenir. Augmente la puissance des capacités de type Poison.', 'buyPrice': 100, 'sellPrice': 50,
            'heldEffectId': 'poison_barb', 'tags': ['held-item'], 'uses': []}]}},
        {'actionId': 'fact.create_batch', 'parameters': {'facts': [
            {'id': VANESSA_FACT, 'label': 'HGSS Vanessa Pic Venin recu', 'defaultValue': False, 'tags': ['hgss', 'c708']},
            {'id': SIBLING_FACT, 'label': 'HGSS fratrie jours rencontres', 'valueType': 'int', 'defaultValue': 0, 'tags': ['hgss', 'c708']}]}},
        {'actionId': 'dialogue.create_batch', 'parameters': {'dialogues': dialogues}},
        copy.deepcopy(preparation['candidateRequests'][1]),
        {'actionId': 'entity.upsert', 'parameters': {'mapId': 'route-32', 'entity': {
            'id': 'ch7-36-14', 'name': 'Vanessa', 'kind': 'npc', 'pos': {'x': 31, 'y': 122}, 'blocksMovement': True,
            'npc': {'displayName': 'Vanessa', 'characterId': 'hgss-habitant-maison-griotte', 'facing': 'west', 'movement': {'mode': 'scriptedOnly'}}}}},
        {'actionId': 'scene.upsert', 'parameters': {'scene': lapras_scene}},
        {'actionId': 'scene.upsert', 'parameters': {'scene': vanessa_scene}},
        {'actionId': 'event_v2.record_upsert_batch', 'parameters': {'records': [lapras_event, vanessa_event]}},
        {'actionId': 'world_rule.upsert_batch', 'parameters': {'rules': [*lapras_rules, *vanessa_rules]}},
    ]
    items = json.loads((work.parents[1] / 'jeu/data/pokemon/catalogs/items.json').read_text())['entries']
    for item_id in ['poke-ball', 'great-ball', 'premier-ball']:
        item = next(row for row in items if row['id'] == item_id)
        capture = copy.deepcopy(item['capture'])
        if 'special' not in capture['allowedEncounterKinds']:
            capture['allowedEncounterKinds'].append('special')
            requests.append({'actionId': 'item.set_capture_effect', 'parameters': {'itemId': item_id, 'capture': capture}})
    source = work.parents[1] / 'jeu'
    sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
    witnesses = [work / 'revisites/preparation.json', reference / 'dialogues/banques/0752.json',
        reference / 'sources/decompilation/files/fielddata/script/scr_seq/scr_seq_0058_D25R0103.s',
        reference / 'sources/decompilation/files/fielddata/script/scr_seq/scr_seq_0232_R32.s',
        Path(__file__), data / 'assets/lapras.png', data / 'assets/poison-barb.png']
    return {'schema': 'heartgold.c708.intent.v1', 'requests': requests,
        'guards': {key: sha(source / key) for key in ['project.json', 'catalog/HEAD.json', 'assets/.pokemap-assets.json',
            'maps/route-32.json', 'maps/caves-jumelles-sous-sol2.json', 'data/pokemon/catalogs/items.json']},
        'sourceWitnesses': {str(path): sha(path) for path in witnesses},
        'scope': 'Lokhlass vendredi niveau20 et Vanessa vendredi/Pic Venin unique ; contacts existants préservés.',
        'nativeSpriteSha256': atlas['sha256']}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('work', type=Path)
    args = parser.parse_args()
    result = build(args.work.resolve())
    destination = args.work / 'revisites/c7-08/intention.json'
    if destination.exists(): raise ValueError('Preserve the frozen intention.')
    destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'actions': len(result['requests'])}))
