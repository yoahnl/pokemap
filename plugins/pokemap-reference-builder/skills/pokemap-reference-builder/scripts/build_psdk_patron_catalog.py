import argparse
import csv
import hashlib
import html
import json
import math
from collections import Counter
from pathlib import Path

from PIL import Image, ImageChops


GUIDE_COLORS = ((255, 245, 104), (240, 91, 161))
EXCLUDED_SHEETS = {
    'passages.png': 'Marqueurs de passage, pas des dessins d’objets.',
    'prio_w.png': 'Marqueurs techniques de priorité.',
    'terrain_tag.png': 'Marqueurs techniques de terrain.',
    'TECH-borders.png': 'Bordures techniques et raccords de surfaces, hors patrons d’objets.',
}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def remove_guides(image):
    image = image.convert('RGBA')
    rgb = image.convert('RGB')
    alpha = image.getchannel('A')
    for color in GUIDE_COLORS:
        channels = ImageChops.difference(rgb, Image.new('RGB', image.size, color)).split()
        difference = ImageChops.lighter(ImageChops.lighter(channels[0], channels[1]), channels[2])
        keep = difference.point(lambda value: 0 if value == 0 else 255)
        alpha = ImageChops.darker(alpha, keep)
    image.putalpha(alpha)
    return image


def rectangle(bounds):
    if bounds is None:
        return None
    left, top, right, bottom = bounds
    return {'x': left, 'y': top, 'width': right - left, 'height': bottom - top}


def measure(image):
    alpha = image.getchannel('A')
    all_bounds = rectangle(alpha.getbbox())
    opaque_bounds = rectangle(alpha.point(lambda value: 255 if value >= 128 else 0).getbbox())
    histogram = alpha.histogram()
    return {
        'canvasPx': {'width': image.width, 'height': image.height},
        'canvasCells': {'width': image.width / 32, 'height': image.height / 32},
        'visibleBoundsPx': all_bounds,
        'artBoundsPx': opaque_bounds,
        'minimumCanvasCells': {
            'width': math.ceil(all_bounds['width'] / 32) if all_bounds else 0,
            'height': math.ceil(all_bounds['height'] / 32) if all_bounds else 0,
        },
        'alpha': {'transparent': histogram[0], 'translucent': sum(histogram[1:255]), 'opaque': histogram[255]},
    }


def read_definitions(paths):
    entries, sheets = [], {}
    for path in paths:
        data = json.loads(path.read_text())
        entries.extend(data['entries'])
        for sheet in data.get('sheets', []):
            sheets[sheet['source']] = sheet['coverageNote']
    return entries, sheets


def crop_entry(entry, assets):
    source = assets / entry['source']
    image = Image.open(source).convert('RGBA')
    x, y, width, height = entry['rect']
    if min(x, y) < 0 or min(width, height) <= 0 or x + width > image.width or y + height > image.height:
        raise ValueError(f"Rectangle hors source : {entry['id']}")
    result = {**entry, 'sourceRectPx': {'x': x, 'y': y, 'width': width, 'height': height}}
    del result['rect']
    result['image'] = remove_guides(image.crop((x, y, x + width, y + height)))
    result['measurementBasis'] = 'source_rectangle'
    result['sourceCells'] = []
    result['anchor'] = None
    result['collisionCells'] = None
    result['confidence'] = 'rectangle_revu'
    return result


def finalize_entry(entry, output, seen):
    image = entry.pop('image').convert('RGBA')
    if image.width % 32 or image.height % 32:
        canvas = Image.new('RGBA', (math.ceil(image.width / 32) * 32, math.ceil(image.height / 32) * 32))
        canvas.alpha_composite(image)
        image = canvas
    metrics = measure(image)
    if metrics['visibleBoundsPx'] is None:
        raise ValueError(f"Patron vide : {entry['id']}")
    entry.update(metrics)
    entry.setdefault('notes', '')
    entry.setdefault('collisionCells', None)
    entry.setdefault('anchor', None)
    entry.setdefault('confidence', 'regle_tiled')
    entry.setdefault('measurementBasis', 'tiled_rule')
    entry.setdefault('source', ', '.join(sorted(set(cell['source'] for cell in entry.get('sourceCells', [])))))
    art = image.crop(image.getbbox())
    normalized = Image.new('RGBA', art.size)
    normalized.alpha_composite(art)
    digest = hashlib.sha256(str(art.size).encode() + normalized.tobytes()).hexdigest()
    entry['visualSha256'] = digest
    entry['sameVisualAs'] = seen.get(digest)
    seen.setdefault(digest, entry['id'])
    entry['preview'] = f"vignettes/{entry['id']}.png"
    destination = output / entry['preview']
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)
    entry['previewSha256'] = sha256(destination)
    return entry


def write_csv(catalog, path):
    fields = ['id', 'nom', 'famille', 'type', 'canevas_px', 'canevas_cases_32', 'dessin_px', 'avec_ombre_px', 'source', 'rectangle_source_px', 'regle', 'ancre_mesuree', 'collision', 'doublon_visuel_de', 'notes']
    with path.open('w', encoding='utf-8-sig', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter=';')
        writer.writeheader()
        for row in catalog['entries']:
            def dimensions(value):
                return f"{value['width']} × {value['height']}" if value else ''
            writer.writerow({
                'id': row['id'], 'nom': row['label'], 'famille': row['family'], 'type': row['kind'],
                'canevas_px': dimensions(row['canvasPx']), 'canevas_cases_32': dimensions(row['canvasCells']),
                'dessin_px': dimensions(row['artBoundsPx']), 'avec_ombre_px': dimensions(row['visibleBoundsPx']),
                'source': row['source'], 'rectangle_source_px': json.dumps(row.get('sourceRectPx'), ensure_ascii=False),
                'regle': row.get('ruleMap', ''), 'ancre_mesuree': json.dumps(row.get('anchor'), ensure_ascii=False),
                'collision': 'À définir' if row['collisionCells'] is None else json.dumps(row['collisionCells']),
                'doublon_visuel_de': row['sameVisualAs'] or '', 'notes': row['notes'],
            })


def write_html(catalog, path):
    data = json.dumps(catalog, ensure_ascii=False).replace('</', '<\\/')
    template = '''<!doctype html>
<html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Patrons d’assets — Avelune Studio</title>
<style>
:root{color-scheme:light;--ink:#23332f;--muted:#63716a;--line:#dce3da;--paper:#f8f8f2;--green:#255d44;--accent:#c8df91}*{box-sizing:border-box}body{margin:0;background:var(--paper);font:15px/1.5 system-ui,sans-serif;color:var(--ink)}main{max-width:1500px;margin:auto;padding:40px 28px}header{border-bottom:1px solid var(--line);padding-bottom:25px;display:grid;grid-template-columns:1fr auto;gap:25px}.eyebrow{letter-spacing:.13em;font-size:11px;font-weight:800;color:var(--green)}h1{font-size:38px;letter-spacing:-.04em;margin:8px 0}header p{max-width:820px;color:var(--muted);margin:8px 0}.downloads{display:flex;align-items:start;gap:10px;padding-top:30px}a{color:var(--green)}.button,button,select,input{font:inherit;border:1px solid var(--line);border-radius:8px;padding:9px 12px;background:white;color:var(--ink)}button,.button{cursor:pointer;text-decoration:none}.button.primary{background:var(--green);color:white}.stats{display:flex;gap:36px;margin:25px 0}.stats b{display:block;font-size:26px}.stats span{font-size:12px;color:var(--muted)}.note{padding:15px 18px;border-left:3px solid var(--green);background:#edf1e4;color:#415044;font-size:13px}.controls{display:flex;flex-wrap:wrap;gap:9px;margin:24px 0 12px;position:sticky;top:0;padding:12px 0;background:var(--paper);z-index:2}.controls input{flex:1;min-width:230px}#count{color:var(--muted);font-size:13px;margin:10px 0}table{width:100%;border-collapse:collapse;background:white}th{text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:12px;border-bottom:2px solid var(--line)}td{padding:14px 12px;border-bottom:1px solid var(--line);vertical-align:middle}td small{display:block;font-size:12px;color:var(--muted);max-width:320px}td.name{min-width:230px}td.name strong{display:block}.thumb{width:132px;height:116px;display:flex;align-items:center;justify-content:center;background-color:#e8eee0;background-image:linear-gradient(45deg,#dde5d7 25%,transparent 25%),linear-gradient(-45deg,#dde5d7 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#dde5d7 75%),linear-gradient(-45deg,transparent 75%,#dde5d7 75%);background-size:16px 16px;background-position:0 0,0 8px,8px -8px,-8px 0;border:0}.thumb img{max-width:124px;max-height:108px;image-rendering:pixelated}.badge{display:inline-block;padding:2px 8px;margin:4px 4px 2px 0;border-radius:20px;font-size:11px;background:#edf1e8}.badge.module{background:#fff0d8}.num{white-space:nowrap;font-variant-numeric:tabular-nums}details{margin-top:25px;border-top:1px solid var(--line);padding-top:18px}summary{cursor:pointer;font-weight:650}.coverage{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:12px;margin-top:15px}.coverage div{background:white;border:1px solid var(--line);padding:14px;font-size:12px}.coverage b{display:block}.table-wrap{overflow:auto}dialog{width:min(1000px,95vw);max-height:90vh;border:0;border-radius:12px;padding:26px;background:var(--paper);color:var(--ink)}dialog::backdrop{background:#14231bcc}dialog .stage{overflow:auto;max-height:52vh;background:#dce5d3;text-align:center;padding:20px;margin:20px 0}dialog img{image-rendering:pixelated;max-width:none}dialog pre{white-space:pre-wrap;font-size:12px}dialog button{margin-right:8px}footer{font-size:12px;color:var(--muted);margin:30px 0}@media(max-width:760px){main{padding:24px 14px}header{display:block}h1{font-size:29px}.downloads{padding-top:10px}.stats{gap:20px}td{padding:10px}.controls{position:static}}
</style><main><header><div><div class="eyebrow">AVELUNE STUDIO · BIBLIOTHÈQUE DE PROPORTIONS</div><h1>Les patrons de nos futurs assets.</h1><p>Maisons, végétation, mobilier et équipements mesurés dans le corpus PSDK. Choisis un dessin, relève son canevas, puis crée notre version à la même échelle.</p></div><div class="downloads"><a class="button primary" href="patrons.csv" download>Table CSV ↓</a><a class="button" href="patrons.json" download>Données JSON ↓</a></div></header>
<section class="stats" id="stats"></section><p class="note"><b>Une case = 32 × 32 px.</b> Le <b>canevas</b> est l’espace à réserver dans l’atlas ; le <b>dessin</b> est sa zone visible avec alpha ≥ 128. « Avec ombre » inclut tous les pixels d’alpha non nul. Ces rectangles ne sont <b>pas des collisions</b>. Les modules restent des pièces à assembler. Les noms sont descriptifs, pas des identifiants officiels du SDK.</p>
<div class="controls"><input id="search" type="search" placeholder="Maison, arbre, banc, identifiant…" aria-label="Rechercher un patron"><select id="family" aria-label="Famille"><option value="">Toutes les familles</option></select><select id="kind" aria-label="Type"><option value="">Tous les types</option><option value="assembled">Assemblés par Tiled</option><option value="object">Objets isolés</option><option value="module">Pièces modulaires</option></select><select id="sort" aria-label="Trier"><option value="default">Ordre du catalogue</option><option value="width">Largeur croissante</option><option value="height">Hauteur croissante</option><option value="area">Surface croissante</option></select><label><input id="unique" type="checkbox"> Masquer les doublons visuels</label></div><p id="count"></p><div class="table-wrap"><table><thead><tr><th>Aperçu</th><th>Patron</th><th>Canevas / cases</th><th>Dessin / avec ombre</th><th>Origine / usage</th></tr></thead><tbody id="rows"></tbody></table></div>
<details><summary>Couverture des 21 planches et méthode de mesure</summary><p>Les assemblages conservent les coordonnées relatives des règles Tiled. Les rectangles des objets isolés ont été relus sur les planches originales. Le rose et le jaune exacts de repérage ont été rendus transparents uniquement dans ces aperçus. Les sources n’ont pas été modifiées.</p><div class="coverage" id="coverage"></div><p>La présence d’un patron ne certifie ni une collision ni une animation en jeu. Les calques passages des règles sont conservés dans les données brutes lorsqu’ils existent ; leur interprétation n’est pas inventée. Les changements artistiques, points d’entrée et ombres finales restent à définir pour le nouvel asset.</p></details><footer id="footer"></footer></main>
<dialog id="detail"><button id="close">Fermer</button><button id="zoom">Zoom ×2</button><h2 id="detail-name"></h2><div class="stage"><img id="detail-image" alt="Patron sélectionné"></div><pre id="detail-meta"></pre></dialog>
<script type="application/json" id="catalog">__DATA__</script><script>
const catalog=JSON.parse(document.getElementById('catalog').textContent),all=catalog.entries,$=id=>document.getElementById(id),esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])),dims=v=>v?`${v.width} × ${v.height}`:'—',families={architecture:'Architecture',vegetation:'Végétation',mobilier:'Mobilier',equipement:'Équipements',decoration:'Décors',buildings:'Architecture',trees:'Végétation',nature:'Végétation',assets:'Équipements'},types={assembled:'Assemblage Tiled',object:'Objet isolé',module:'Module'};
$('stats').innerHTML=[[all.length,'patrons et modules'],[new Set(all.map(e=>e.visualSha256)).size,'dessins distincts'],[all.filter(e=>e.kind==='assembled').length,'assemblages Tiled'],[catalog.sourceInventory.length,'planches examinées']].map(([n,t])=>`<div><b>${n}</b><span>${t}</span></div>`).join('');
for(const family of [...new Set(all.map(e=>e.family))].sort())$('family').insertAdjacentHTML('beforeend',`<option value="${esc(family)}">${esc(families[family]||family)}</option>`);
function render(){const query=$('search').value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,''),family=$('family').value,kind=$('kind').value;let filtered=all.filter(e=>(!family||e.family===family)&&(!kind||e.kind===kind)&&(!$('unique').checked||!e.sameVisualAs)&&JSON.stringify([e.id,e.label,e.source,e.notes]).toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').includes(query));const sort=$('sort').value;if(sort!=='default')filtered.sort((a,b)=>sort==='area'?a.canvasPx.width*a.canvasPx.height-b.canvasPx.width*b.canvasPx.height:a.canvasPx[sort]-b.canvasPx[sort]);$('count').textContent=`${filtered.length} patron${filtered.length>1?'s':''} affiché${filtered.length>1?'s':''} sur ${all.length} · Cliquez sur une vignette pour voir le détail et les coordonnées.`;$('rows').innerHTML=filtered.map(e=>`<tr><td><button class="thumb" data-id="${esc(e.id)}" aria-label="Voir ${esc(e.label)}"><img loading="lazy" src="${esc(e.preview)}" alt="${esc(e.label)}"></button></td><td class="name"><strong>${esc(e.label)}</strong><small>${esc(e.id)}</small><span class="badge ${e.kind}">${types[e.kind]||esc(e.kind)}</span><span class="badge">${families[e.family]||esc(e.family)}</span>${e.sameVisualAs?'<small>Même dessin : '+esc(e.sameVisualAs)+'</small>':''}</td><td class="num"><b>${dims(e.canvasPx)} px</b><small>${dims(e.canvasCells)} cases</small></td><td class="num">${dims(e.artBoundsPx)} px<small>Avec ombre : ${dims(e.visibleBoundsPx)} px</small></td><td><small>${esc(e.source)}</small><small>${e.ruleMap?'Règle : '+esc(e.ruleMap):'Découpe source mesurée'}</small><small>${esc(e.notes)}</small></td></tr>`).join('')}
for(const id of ['search','family','kind','sort','unique'])$(id).addEventListener(id==='search'?'input':'change',render);
let selected,zoom=1;function setZoom(){const im=$('detail-image');im.style.width=selected.canvasPx.width*zoom+'px';im.style.height=selected.canvasPx.height*zoom+'px';$('zoom').textContent=zoom===1?'Zoom ×2':'Zoom ×1'}$('rows').addEventListener('click',event=>{const button=event.target.closest('[data-id]');if(!button)return;selected=all.find(e=>e.id===button.dataset.id);zoom=1;$('detail-name').textContent=selected.label;$('detail-image').src=selected.preview;setZoom();$('detail-meta').textContent=JSON.stringify({id:selected.id,canevas:selected.canvasPx,cases:selected.canvasCells,dessin:selected.artBoundsPx,avecOmbre:selected.visibleBoundsPx,source:selected.source,rectangle:selected.sourceRectPx,carteRegle:selected.ruleMap,rectangleRegle:selected.ruleRect,ancreMesuree:selected.anchor,collision:selected.collisionCells===null?'À définir':selected.collisionCells,notes:selected.notes},null,2);$('detail').showModal()});$('close').onclick=()=>$('detail').close();$('zoom').onclick=()=>{zoom=zoom===1?2:1;setZoom()};
$('coverage').innerHTML=catalog.sourceInventory.map(s=>`<div><b>${esc(s.source)} · ${s.width} × ${s.height} px</b>${s.entries} références dans la table.<br>${esc(s.coverageNote)}</div>`).join('');$('footer').textContent='Mesures reproductibles · Sources conservées · '+catalog.generatedOn+' · Le catalogue reste une base de travail à relire visuellement avant création.';render();
</script></html>'''
    path.write_text(template.replace('__DATA__', data), encoding='utf-8')


def build(tiled_root, output, definitions):
    from psdk_rule_patterns import extract_rules

    assets = tiled_root / 'Assets'
    tracked_sources = sorted(assets.glob('*.png')) + sorted((tiled_root / 'Maps').glob('rules_TECH_*.tmx')) + sorted((tiled_root / 'Tilesets').glob('*.tsx'))
    hashes_before = {str(path.relative_to(tiled_root)): sha256(path) for path in tracked_sources}
    definitions, sheet_notes = read_definitions(definitions)
    entries = extract_rules(tiled_root)
    for entry in entries:
        entry['family'] = {'buildings': 'architecture', 'trees': 'vegetation', 'nature': 'vegetation', 'assets': 'equipement'}.get(entry['family'], entry['family'])
    entries.extend(crop_entry(entry, assets) for entry in definitions)
    ids = [entry['id'] for entry in entries]
    if len(ids) != len(set(ids)):
        raise ValueError('Identifiants de patrons dupliqués')
    output.mkdir(parents=True, exist_ok=True)
    seen = {}
    entries = [finalize_entry(entry, output, seen) for entry in entries]
    inventory = []
    for source in sorted(assets.glob('*.png')):
        image = Image.open(source)
        count = sum(source.name in row['source'].split(', ') for row in entries)
        inventory.append({
            'source': source.name, 'width': image.width, 'height': image.height, 'sha256': hashes_before[str(source.relative_to(tiled_root))],
            'entries': count,
            'coverageNote': EXCLUDED_SHEETS.get(source.name, sheet_notes.get(source.name, 'Assemblages issus des règles Tiled ; surfaces répétables et repères exclus.')),
        })
    catalog = {
        'schemaVersion': 1, 'generatedOn': '2026-09-03', 'cellSizePx': 32, 'sourceRoot': str(tiled_root),
        'scope': 'Patrons dimensionnels de props, végétation, mobilier et architecture. Sols et surfaces répétables exclus.',
        'measurementPolicy': {'guideColorsRgb': GUIDE_COLORS, 'artAlphaThreshold': 128, 'collisionInferred': False, 'anchorsInferred': False, 'sourceScale': 1},
        'sourceInventory': inventory, 'sourceHashes': hashes_before, 'entries': entries,
    }
    if any(sha256(path) != hashes_before[str(path.relative_to(tiled_root))] for path in tracked_sources):
        raise ValueError('Une source a changé pendant la mesure')
    (output / 'patrons.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    write_csv(catalog, output / 'patrons.csv')
    write_html(catalog, output / 'index.html')
    summary = {'entries': len(entries), 'uniqueVisuals': len(seen), 'families': dict(Counter(row['family'] for row in entries)), 'kinds': dict(Counter(row['kind'] for row in entries)), 'sourcesUnchanged': True, 'sourcesMeasured': len(inventory), 'emptySources': [s['source'] for s in inventory if not s['entries'] and s['source'] not in EXCLUDED_SHEETS]}
    (output / 'verification.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False))


def check(output):
    catalog = json.loads((output / 'patrons.json').read_text())
    errors = []
    ids = set()
    for row in catalog['entries']:
        if row['id'] in ids:
            errors.append(f"duplicate:{row['id']}")
        ids.add(row['id'])
        path = output / row['preview']
        if not path.exists() or sha256(path) != row['previewSha256']:
            errors.append(f"preview:{row['id']}")
            continue
        measured = measure(Image.open(path).convert('RGBA'))
        if any(measured[key] != row[key] for key in measured):
            errors.append(f"measurement:{row['id']}")
    for relative, digest in catalog['sourceHashes'].items():
        source = Path(catalog['sourceRoot']) / relative
        if not source.exists() or sha256(source) != digest:
            errors.append(f"source:{relative}")
    print(json.dumps({'checkedEntries': len(ids), 'checkedSources': len(catalog['sourceHashes']), 'errors': errors}, ensure_ascii=False))
    if errors:
        raise SystemExit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--tiled-root', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--check-only', action='store_true')
    parser.add_argument('--definitions', nargs='*', type=Path)
    args = parser.parse_args()
    if args.check_only:
        check(args.output)
        return
    if args.tiled_root is None:
        parser.error('--tiled-root est requis pour construire le catalogue')
    refs = Path(__file__).resolve().parent.parent / 'references'
    definitions = args.definitions or [refs / 'psdk-outdoor-patrons.json', refs / 'psdk-interior-patrons.json', refs / 'psdk-nature-patrons.json']
    build(args.tiled_root, args.output, definitions)


if __name__ == '__main__':
    main()
