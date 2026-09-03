import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from PIL import Image

from build_psdk_patron_catalog import check, crop_entry, finalize_entry, measure, remove_guides, sha256


class PatronMeasurementTest(unittest.TestCase):
    def test_guides_are_exact_and_real_shadow_alpha_survives(self):
        image = Image.new('RGBA', (5, 1))
        image.putdata([(255, 245, 104, 255), (240, 91, 161, 255), (240, 90, 161, 255), (0, 0, 0, 76), (255, 255, 255, 255)])
        result = remove_guides(image)
        self.assertEqual(list(result.getchannel('A').tobytes()), [0, 0, 255, 76, 255])
        self.assertEqual(image.getpixel((0, 0)), (255, 245, 104, 255))

    def test_art_and_shadow_have_separate_bounds(self):
        image = Image.new('RGBA', (64, 96))
        image.paste((90, 120, 70, 255), (16, 10, 46, 78))
        image.paste((0, 0, 0, 76), (10, 78, 54, 90))
        result = measure(image)
        self.assertEqual(result['canvasCells'], {'width': 2, 'height': 3})
        self.assertEqual(result['artBoundsPx'], {'x': 16, 'y': 10, 'width': 30, 'height': 68})
        self.assertEqual(result['visibleBoundsPx'], {'x': 10, 'y': 10, 'width': 44, 'height': 80})
        self.assertEqual(result['alpha']['translucent'], 528)

    def test_out_of_bounds_crop_is_rejected_without_source_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'sheet.png'
            Image.new('RGBA', (32, 32), 'green').save(source)
            before = source.read_bytes()
            with self.assertRaises(ValueError):
                crop_entry({'id': 'bad', 'source': 'sheet.png', 'rect': [16, 0, 32, 32]}, root)
            self.assertEqual(source.read_bytes(), before)

    def test_padding_preserves_pixel_scale_and_does_not_infer_collision(self):
        with tempfile.TemporaryDirectory() as directory:
            image = Image.new('RGBA', (18, 45), (70, 120, 90, 255))
            entry = finalize_entry({'id': 'plant', 'image': image, 'sourceCells': [], 'notes': []}, Path(directory), {})
            self.assertEqual(entry['canvasPx'], {'width': 32, 'height': 64})
            self.assertEqual(entry['artBoundsPx']['width'], 18)
            self.assertIsNone(entry['collisionCells'])
            self.assertIsNone(entry['anchor'])
            exported = Image.open(Path(directory) / entry['preview'])
            self.assertEqual(exported.getpixel((17, 44)), (70, 120, 90, 255))
            self.assertEqual(exported.getpixel((18, 44))[3], 0)
            json.dumps(entry)

    def test_empty_candidate_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                finalize_entry({'id': 'empty', 'image': Image.new('RGBA', (32, 32))}, Path(directory), {})

    def test_changed_definitions_make_a_previous_catalog_stale(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            definitions = root / 'definitions.json'
            definitions.write_text('{"rect": [0, 0, 32, 32]}')
            catalog = {'entries': [], 'sourceHashes': {}, 'generationHashes': {str(definitions): sha256(definitions)}}
            (root / 'patrons.json').write_text(json.dumps(catalog))
            with redirect_stdout(io.StringIO()):
                check(root)
            definitions.write_text('{"rect": [0, 0, 64, 32]}')
            result = io.StringIO()
            with redirect_stdout(result), self.assertRaises(SystemExit):
                check(root)
            self.assertEqual(json.loads(result.getvalue())['errors'], [f'generation:{definitions}'])


if __name__ == '__main__':
    unittest.main()
