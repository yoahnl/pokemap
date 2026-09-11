import argparse
import html
import json
import math
from pathlib import Path
from PIL import Image


def registration(reference_size, candidate_size, aspect_tolerance=0.01):
    rw, rh = reference_size
    cw, ch = candidate_size
    if min(rw, rh, cw, ch) <= 0:
        raise ValueError('Image dimensions must be positive')
    if abs((rw / rh) / (cw / ch) - 1) > aspect_tolerance:
        raise ValueError('Different aspect ratios: review the crop before comparing')
    scale = min(cw / rw, ch / rh)
    return scale, (cw - rw * scale) / 2, (ch - rh * scale) / 2


def visible_world_bounds(image, source_cells, position, cell_size):
    sx, sy, sw, sh = source_cells
    frame = image.convert('RGBA').crop((sx * cell_size, sy * cell_size, (sx + sw) * cell_size, (sy + sh) * cell_size))
    bounds = frame.getchannel('A').point(lambda alpha: 255 if alpha == 255 else 0).getbbox()
    if bounds is None:
        raise ValueError('No visible opaque artwork in the selected frame')
    px, py = position
    return [bounds[0] + px * cell_size, bounds[1] + py * cell_size, bounds[2] + px * cell_size, bounds[3] + py * cell_size]


def compare_bounds(reference, candidate, cell_size):
    ax, ay, ar, ab = reference
    bx, by, br, bb = candidate
    if min(ar - ax, ab - ay, br - bx, bb - by, cell_size) <= 0:
        raise ValueError('Bounds and cell size must be nonzero')
    intersection = max(0, min(ar, br) - max(ax, bx)) * max(0, min(ab, bb) - max(ay, by))
    union = (ar - ax) * (ab - ay) + (br - bx) * (bb - by) - intersection
    return {
        'centerErrorCells': round(math.hypot((ax + ar - bx - br) / 2, (ay + ab - by - bb) / 2) / cell_size, 3),
        'silhouetteBottomErrorCells': round((bb - ab) / cell_size, 3),
        'widthRatio': round((br - bx) / (ar - ax), 3),
        'heightRatio': round((bb - by) / (ab - ay), 3),
        'iou': round(intersection / union, 3),
    }


def analyze(profile, project_root, map_path, render_path, asset_overrides=None):
    project_root = Path(project_root)
    manifest = json.loads((project_root / 'project.json').read_text())
    map_data = json.loads(Path(map_path).read_text())
    reference = Path(profile['referenceImage']).resolve()
    with Image.open(reference) as image:
        reference_size = image.size
    with Image.open(render_path) as image:
        candidate_size = image.size
    cell = profile.get('cellSizePx', 32)
    expected = (map_data['size']['width'] * cell, map_data['size']['height'] * cell)
    if candidate_size != expected:
        raise ValueError(f'Render must use native cell size: expected {expected}, got {candidate_size}')
    scale, ox, oy = registration(reference_size, candidate_size)
    elements = {entry['id']: entry for entry in manifest['elements']}
    tilesets = {entry['id']: entry for entry in manifest['tilesets']}
    placements = {entry['id']: entry for entry in map_data['placedElements']}
    rows = []
    for landmark in profile['landmarks']:
        instance = placements.get(landmark['instanceId'])
        if instance is None:
            rows.append({'id': landmark['id'], 'status': 'missing'})
            continue
        element = elements[instance['elementId']]
        frame = element['frames'][0]
        source = frame['source']
        override = (asset_overrides or {}).get(element['id'])
        asset = Path(override) if override else project_root / tilesets[frame['tilesetId']]['relativePath']
        with Image.open(asset) as image:
            bounds = visible_world_bounds(image, [source[k] for k in ['x', 'y', 'width', 'height']], [instance['pos']['x'], instance['pos']['y']], cell)
        reference_bounds = [value * scale + (ox if index % 2 == 0 else oy) for index, value in enumerate(landmark['referenceBoundsPx'])]
        rows.append({'id': landmark['id'], 'status': 'measured', 'referenceBoundsPx': reference_bounds, 'candidateBoundsPx': bounds, **compare_bounds(reference_bounds, bounds, cell)})
    return {'referenceImage': str(reference), 'candidateImage': str(Path(render_path).resolve()), 'referenceUri': reference.as_uri(), 'candidateUri': Path(render_path).resolve().as_uri(), 'referenceSizePx': reference_size, 'candidateSizePx': candidate_size, 'registration': {'uniformScale': scale, 'offsetPx': [ox, oy]}, 'exceptions': profile.get('exceptions', []), 'landmarks': rows, 'artisticVerdict': 'human_review_required', 'limits': 'Alpha 255 silhouette bounds measure scale and placement only. They do not identify a ground anchor or separate an opaque baked shadow. Roof geometry, palette, shadows, forest mass, occlusion, collision and artistic fidelity need separate inspection.'}


def review_html(report):
    width, height = report['candidateSizePx']
    table = ''.join('<tr>' + ''.join(f'<td>{html.escape(str(row.get(key, "—")))}</td>' for key in ['id', 'centerErrorCells', 'silhouetteBottomErrorCells', 'widthRatio', 'heightRatio', 'iou']) + '</tr>' for row in report['landmarks'])
    boxes = []
    for row in report['landmarks']:
        for key, color in [('referenceBoundsPx', '#ffd55e'), ('candidateBoundsPx', '#6cedda')]:
            if key in row:
                x, y, right, bottom = row[key]
                boxes.append(f'<rect x="{x}" y="{y}" width="{right-x}" height="{bottom-y}" fill="none" stroke="{color}" stroke-width="3"/>')
    payload = json.dumps(report, ensure_ascii=False).replace('<', '\\u003c')
    return f'''<!doctype html><html lang="fr"><meta charset="utf-8"><title>Recalage de la carte</title>
<style>body{{background:#19221e;color:#e5efe8;font:16px system-ui;margin:24px}}main{{max-width:1400px;margin:auto}}.view{{position:relative;width:100%;aspect-ratio:{width}/{height};background:#111}}.view img,.view svg{{position:absolute;width:100%;height:100%;object-fit:contain;image-rendering:pixelated}}table{{border-collapse:collapse;margin-top:24px}}td,th{{padding:10px;border-bottom:1px solid #496052;text-align:left}}input{{width:300px}}button{{margin:8px;padding:8px}}p{{max-width:950px;line-height:1.5}}</style>
<main><h1>Référence ↔ carte éditable</h1><p>Déplacer le curseur pour superposer les images. Jaune : silhouette de référence ; vert : pixels opaques de l’asset, marges transparentes exclues. Une ombre opaque intégrée ne peut pas être séparée automatiquement. Le recalage utilise une échelle uniforme.</p>
<label>Opacité du rendu <input id="blend" type="range" min="0" max="100" value="55"></label><button id="toggle">Afficher / masquer les repères</button>
<div class="view"><img id="ref"><img id="candidate" style="opacity:.55"><svg id="boxes" viewBox="0 0 {width} {height}">{''.join(boxes)}</svg></div>
<table><thead><tr><th>Repère</th><th>Écart centre (cases)</th><th>Écart bas du dessin (cases)</th><th>Largeur / réf.</th><th>Hauteur / réf.</th><th>Intersection / union</th></tr></thead><tbody>{table}</tbody></table>
<p>Un rapport de taille de 1 correspond à la référence, sans être une obligation : la charte, les patrons natifs et le personnage priment pour les proportions. Ces mesures ne donnent aucun score de fidélité artistique. Le bas du dessin n’est pas son ancrage au sol. Les formes, matériaux, ombres, masses végétales et accès demandent une inspection séparée.</p><p id="exceptions"></p></main>
<script>const r={payload};document.getElementById('ref').src=r.referenceUri;document.getElementById('candidate').src=r.candidateUri;document.getElementById('blend').oninput=e=>document.getElementById('candidate').style.opacity=e.target.value/100;document.getElementById('toggle').onclick=()=>{{const b=document.getElementById('boxes');b.style.display=b.style.display==='none'?'':'none'}};document.getElementById('exceptions').textContent='Écarts intentionnels : '+r.exceptions.map(x=>x.reason||x).join(' ; ');</script></html>'''


def main():
    parser = argparse.ArgumentParser()
    for flag in ['profile', 'project-root', 'map', 'render', 'output', 'html']:
        parser.add_argument('--' + flag, required=True)
    parser.add_argument('--asset-overrides')
    args = parser.parse_args()
    overrides = json.loads(Path(args.asset_overrides).read_text()) if args.asset_overrides else None
    profile_path = Path(args.profile).resolve()
    profile = json.loads(profile_path.read_text())
    if not Path(profile['referenceImage']).is_absolute():
        profile['referenceImage'] = str(profile_path.parent / profile['referenceImage'])
    result = analyze(profile, args.project_root, args.map, args.render, overrides)
    Path(args.output).write_text(json.dumps(result, ensure_ascii=False, indent=2))
    document = review_html(result)
    extension = profile.get('reviewExtension', [])
    tags = []
    for name in extension:
        if Path(name).name != name or Path(name).suffix not in {'.css', '.js'}:
            raise ValueError('Review extensions must be local CSS or JS filenames')
        if not (Path(args.html).parent / name).is_file():
            raise ValueError(f'Missing review extension: {name}')
        safe_name = html.escape(name, quote=True)
        tags.append(f'<link rel="stylesheet" href="{safe_name}">' if name.endswith('.css') else f'<script src="{safe_name}"></script>')
    document = document.replace('</html>', '\n'.join(tags) + '</html>')
    Path(args.html).write_text(document)
    print(json.dumps({'landmarks': len(result['landmarks']), 'output': args.output, 'html': args.html}))


if __name__ == '__main__':
    main()
