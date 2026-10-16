import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('import_psdk_bicycle', Path(__file__).with_name('import_psdk_bicycle.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class BicycleImportTest(unittest.TestCase):
    def test_records_source_and_exact_bytes_without_resizing(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'source' / 'graphics' / 'characters'
            source.mkdir(parents=True)
            pixels = b'\x89PNG\r\n\x1a\n' + b'\0' * 8 + struct.pack('>II', 128, 128)
            for suffix in ('roll', 'stop'):
                (source / f'player_m_cycle_{suffix}.png').write_bytes(pixels)
            output = root / 'output'
            receipt = module.import_bicycle(root / 'source', output, 'm')
            self.assertEqual(receipt['layout']['directions'], ['south', 'west', 'east', 'north'])
            self.assertEqual((output / 'player_m_cycle_roll.png').read_bytes(), pixels)
            self.assertEqual(json.loads((output / 'bicycle_provenance.json').read_text()), receipt)
            with self.assertRaises(ValueError):
                module.import_bicycle(root / 'source', source, 'm')
            with self.assertRaises(ValueError):
                module.import_bicycle(root / 'source', root / 'source', 'm')
            (source / 'player_m_cycle_stop.png').write_bytes(b'invalid')
            with self.assertRaises(ValueError):
                module.import_bicycle(root / 'source', root / 'invalid', 'm')


if __name__ == '__main__':
    unittest.main()
