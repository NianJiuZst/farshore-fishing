#!/usr/bin/env python3
"""Read-only checks for the complete photoreal fish artwork archive."""
import hashlib
import json
from pathlib import Path
import re
from PIL import Image

ROOT = Path(__file__).resolve().parent

def read(name):
    return json.loads((ROOT / name).read_text())

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    manifest = read('asset_manifest.json')
    provenance = {e['species_id']: e for e in read('art_provenance.json')['assets']}
    historical = read('validation_report.json')
    recorded = {e['species_id']: e['checks'] for e in historical['technical_checks']}
    endpoints = read('manual_endpoints.json')
    entries = manifest['assets']
    ids = {e['species_id'] for e in entries}
    errors = []
    checks = []
    def check(label, value):
        checks.append(bool(value))
        if not value:
            errors.append(label)
    check('Complete 44-species manifest', manifest['complete'] and manifest['asset_count'] == len(entries) == len(ids) == 44)
    check('Matching provenance and endpoint sets', ids == set(provenance) == set(endpoints) == set(recorded))
    for directory, suffix in [('masters', ''), ('runtime', ''), ('thumbs', '_thumb')]:
        check(directory + ' exact PNG set', {p.name for p in (ROOT / directory).iterdir()} == {sid + suffix + '.png' for sid in ids})
    widths, hashes = [], set()
    master_bytes = thumb_bytes = 0
    for e in entries:
        sid = e['species_id']
        def asset_check(label, value):
            check(sid + ': ' + label, value)
        master, runtime, thumb = [ROOT / e[k] for k in ['master', 'runtime', 'thumb']]
        asset_check('Relative artwork paths', all(p.resolve().is_relative_to(ROOT) for p in [master, runtime, thumb]))
        sha, tsha = digest(master), digest(thumb)
        with Image.open(master) as im, Image.open(thumb) as ti:
            im.load(); ti.load()
            w, h = im.size
            a = im.getchannel('A')
            strong = a.point(lambda v: 255 if v >= 128 else 0).getbbox()
            box = a.point(lambda v: 255 if v >= e['alpha_threshold_for_bbox'] else 0).getbbox()
            tb = ti.getchannel('A').point(lambda v: 255 if v >= e['alpha_threshold_for_bbox'] else 0).getbbox()
            nose, tail = e['nose_normalized'], e['tail_normalized']
            technical = {
                'rgba': im.mode == 'RGBA',
                'high_resolution': 1536 <= w <= 2172,
                'true_transparency': a.getextrema()[0] == 0 and a.getextrema()[1] > 0,
                'uncropped_strong_alpha': bool(strong) and 0 < strong[0] < strong[2] < w and 0 < strong[1] < strong[3] < h,
                'runtime_identical_master': master.read_bytes() == runtime.read_bytes(),
                'sha256_matches': sha == e['sha256'],
                'unique_generated_pixels': sha not in hashes,
                'thumb_512_max': max(ti.size) <= 512,
                'thumb_hash': tsha == e['thumb_sha256'],
                'ruler_endpoints_present': bool(nose and tail),
                'ruler_points_in_canvas': all(0 <= v <= 1 for point in [nose, tail] for v in point),
                'ruler_large_body_span': abs(nose[0] - tail[0]) > 0.8,
                'eye_side_direction': nose[0] > tail[0] if sid == 'european_plaice' else nose[0] < tail[0],
            }
            for k, v in technical.items():
                asset_check(k, v)
            asset_check('Historical technical results reproduced', technical == recorded[sid])
            asset_check('Master dimensions', [w, h] == [e['width'], e['height']])
            asset_check('Thumbnail dimensions and RGBA', ti.mode == 'RGBA' and list(ti.size) == [e['thumb_width'], e['thumb_height']])
            asset_check('Subject bounds', list(box) == e['subject_bbox_px'])
            asset_check('Normalized subject bounds', [box[0]/w, box[1]/h, box[2]/w, box[3]/h] == e['subject_bbox_normalized'])
            asset_check('Thumbnail bounds', list(tb) == e['thumb_subject_bbox_px'])
            asset_check('Transparency fraction', a.histogram()[0]/(w*h) == e['transparent_fraction'])
            asset_check('Nose endpoint', nose == [endpoints[sid]['nose'][0]/w, endpoints[sid]['nose'][1]/h])
            asset_check('Tail endpoint', tail == [endpoints[sid]['tail'][0]/w, endpoints[sid]['tail'][1]/h])
            asset_check('Ruler extent', e['ruler_extent_normalized'] == [nose[0], tail[0]])
        prov = provenance[sid]
        asset_check('Provenance hash and path', prov['master_sha256'] == sha and prov['master_path'] == e['master'])
        asset_check('Provenance fact references', prov['biological_reference_sources'] == e['fact_sources'])
        asset_check('Prompt and anatomy review', bool(prov['prompt'] and prov['anatomy_review']))
        widths.append(w); hashes.add(sha)
        master_bytes += master.stat().st_size; thumb_bytes += thumb.stat().st_size
    batch_ids = set()
    for batch, size in [('coastal', 13), ('european', 13), ('special', 18)]:
        d = read('batch_' + batch + '_manifest.json')
        raw = d.get('assets', d.get('entries'))
        rows = raw if isinstance(raw, dict) else {r['species_id']: r for r in raw}
        check(batch + ' size', len(rows) == size)
        check(batch + ' distinct coverage', not batch_ids.intersection(rows))
        batch_ids.update(rows)
        check(batch + ' endpoints', read('batch_' + batch + '_endpoints.json') == {sid: endpoints[sid] for sid in rows})
        for sid, row in rows.items():
            prov = provenance[sid]
            check(sid + ' batch prompt', row['prompt'] == prov['prompt'])
            check(sid + ' batch artwork', row.get('master_path', row.get('final_generated_output')) == prov['master_path'])
            check(sid + ' batch hash', row.get('sha256', row.get('master_sha256')) == prov['master_sha256'])
            if batch == 'special':
                check(sid + ' revision prompt', row['anatomical_edit_prompt'] == prov['revision_prompt'])
    check('Full batch coverage', batch_ids == ids)
    check('Recorded byte totals', master_bytes == historical['master_total_bytes'] and thumb_bytes == historical['thumb_total_bytes'])
    check('Recorded width range', [min(widths), max(widths)] == [historical['minimum_width'], historical['maximum_width']])
    history = read('revision_history.json')
    historical_rows = history['assets']
    check('Four non-runtime historical generations', history['not_runtime'] is True and history['asset_count'] == len(historical_rows) == 4)
    check('Exact historical PNG set', {str(p.relative_to(ROOT)) for p in (ROOT/'revision_history').iterdir()} == {r['superseded_artwork'] for r in historical_rows})
    for row in historical_rows:
        sid = row['species_id']; path = ROOT/row['superseded_artwork']; prov = provenance[sid]
        check(sid + ' superseded status and hash', row['status'] == 'superseded_not_for_runtime' and digest(path) == row['superseded_sha256'] and row['superseded_sha256'] != prov['master_sha256'])
        check(sid + ' historical final artwork link', row['final_master'] == prov['master_path'] and row['final_master_sha256'] == prov['master_sha256'])
        check(sid + ' historical prompts retained', bool(row['original_generation_prompt']) and row['revision_prompt'] == (prov['prompt'] if sid == 'european_plaice' else prov['revision_prompt']))
        with Image.open(path) as image:
            image.load()
            check(sid + ' historical dimensions and RGBA', image.mode == 'RGBA' and list(image.size) == row['dimensions'])
    check('Actual plaice regeneration prompt preserved', (ROOT/'plaice_regeneration_prompt.txt').read_text().strip() == provenance['european_plaice']['prompt'])
    forbidden = {'output_hint', 'initial_preview_library_ids', 'source_generated_path', 'source_path', 'output_path', 'qa_composite_path', 'composite_path'}
    private = re.compile(r'libfile_[a-zA-Z0-9]+|[?&](?:sig=|X-Amz-|token=)|Bearer\s+\S+|sk-[A-Za-z0-9]{16,}', re.I)
    def inspect(v, loc):
        if isinstance(v, dict):
            for k, child in v.items():
                check(loc + ': sanitized field ' + k, k not in forbidden)
                inspect(child, loc + '/' + k)
        elif isinstance(v, list):
            for i, child in enumerate(v): inspect(child, loc + '/' + str(i))
        elif isinstance(v, str):
            check(loc + ': no private identifier or machine path', not private.search(v) and not Path(v).is_absolute())
    for path in sorted(ROOT.glob('*.json')): inspect(read(path.name), path.name)
    identity = [(str(p.relative_to(ROOT)), digest(p)) for d in ['masters', 'runtime', 'thumbs'] for p in sorted((ROOT/d).glob('*.png'))]
    report = {
        'complete': not errors, 'asset_count': len(entries), 'production_png_count': len(identity), 'historical_png_count': len(historical_rows), 'total_png_count': len(list(ROOT.rglob('*.png'))),
        'checks_passed': sum(checks), 'checks_total': len(checks), 'errors': errors,
        'master_width_range': [min(widths), max(widths)], 'master_total_bytes': master_bytes,
        'thumb_total_bytes': thumb_bytes,
        'png_identity_sha256': hashlib.sha256(json.dumps(identity, sort_keys=True).encode()).hexdigest(),
        'note': 'Read-only integrity and metadata verification; historical visual reviews are retained, not newly re-certified.'
    }
    print(json.dumps(report, indent=2))
    return 0 if not errors else 1

if __name__ == '__main__':
    raise SystemExit(main())
