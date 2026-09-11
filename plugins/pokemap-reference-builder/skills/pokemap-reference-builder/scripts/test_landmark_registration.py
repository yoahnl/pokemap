import unittest
from PIL import Image
from landmark_registration import registration, visible_world_bounds, compare_bounds

class LandmarkRegistrationTests(unittest.TestCase):
    def test_padding_and_shadow_do_not_define_building_size(self):
        image = Image.new('RGBA', (96, 96))
        image.paste((0, 0, 0, 76), (0, 70, 96, 96))
        image.paste((45, 90, 50, 255), (20, 10, 60, 80))
        self.assertEqual(visible_world_bounds(image, [0, 0, 3, 3], [4, 5], 32), [148, 170, 188, 240])

    def test_atlas_coordinates_are_local_to_the_frame(self):
        image = Image.new('RGBA', (128, 64))
        image.paste((20, 60, 90, 255), (70, 8, 110, 48))
        self.assertEqual(visible_world_bounds(image, [2, 0, 2, 2], [1, 2], 32), [38, 72, 78, 112])

    def test_registration_rejects_different_crop_aspects(self):
        with self.assertRaises(ValueError):
            registration((100, 100), (200, 100))

    def test_smaller_aligned_object_is_not_a_size_match(self):
        result = compare_bounds([0, 0, 100, 100], [25, 25, 75, 75], 32)
        self.assertEqual(result['centerErrorCells'], 0)
        self.assertEqual(result['widthRatio'], 0.5)
        self.assertEqual(result['iou'], 0.25)

    def test_transparent_asset_is_rejected(self):
        with self.assertRaises(ValueError):
            visible_world_bounds(Image.new('RGBA', (32, 32)), [0, 0, 1, 1], [0, 0], 32)

    def test_dark_translucent_shadow_is_not_opaque_artwork(self):
        image = Image.new('RGBA', (96, 96))
        image.paste((0, 0, 0, 160), (0, 70, 96, 96))
        image.paste((45, 90, 50, 255), (20, 10, 60, 80))
        self.assertEqual(visible_world_bounds(image, [0, 0, 3, 3], [0, 0], 32), [20, 10, 60, 80])

if __name__ == '__main__':
    unittest.main()
