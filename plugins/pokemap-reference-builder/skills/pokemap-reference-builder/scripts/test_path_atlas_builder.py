from __future__ import annotations

import tempfile
import unittest
import xml.etree.ElementTree as ET
from argparse import Namespace
from pathlib import Path

from PIL import Image

import path_atlas_builder as builder
from path_atlas_builder import adapt_erw_ground_pixel, adjust_texture_hsv, apply_erw_water_inner_shadow, apply_water_shoreline, build_bank, build_erw_ground, build_erw_water, build_erw_water_retune, build_grass_fill, build_ground, build_sampled_corner, build_sampled_corner_animated, build_sampled_ground, build_water


class PathAtlasBuilderTest(unittest.TestCase):
    def test_erw_wang_canonical_keeps_one_native_candidate_per_signature(self) -> None:
        self.assertTrue(hasattr(builder, "build_erw_wang_canonical"))
        build_erw_wang_canonical = getattr(builder, "build_erw_wang_canonical")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            source_tsx = root / "source.tsx"
            output_png = root / "canonical.png"
            output_tsx = root / "canonical.tsx"
            Image.new("RGBA", (96, 32), (75, 175, 74, 255)).save(source_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="3" columns="3">'
                '<image source="source.png" width="96" height="32"/>'
                '<wangsets><wangset name="Terrain" type="corner" tile="0">'
                '<wangcolor name="Terrain" color="#00ff00" tile="0" probability="1"/>'
                '<wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>'
                '<wangtile tileid="1" wangid="0,1,0,1,0,1,0,1"/>'
                '<wangtile tileid="2" wangid="0,1,0,0,0,0,0,0"/>'
                '</wangset></wangsets></tileset>',
                encoding="utf-8",
            )

            build_erw_wang_canonical(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    wang_set_index=0,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="ERW canonical terrain",
                )
            )

            adapted = ET.parse(output_tsx).getroot()
            tiles = adapted.findall("wangsets/wangset/wangtile")
            self.assertEqual([tile.attrib["tileid"] for tile in tiles], ["0", "2"])
            self.assertEqual(adapted.find("image").attrib["source"], "canonical.png")
            with Image.open(output_png) as output:
                self.assertEqual(output.size, (96, 32))
                self.assertEqual(output.info["Description"], "ERW canonical terrain")

    def test_erw_water_edge_highlight_preserves_banks_center_and_animation(self) -> None:
        self.assertTrue(hasattr(builder, "build_erw_water_edge_highlight"))
        build_erw_water_edge_highlight = getattr(builder, "build_erw_water_edge_highlight")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            mask_png = root / "mask.png"
            source_tsx = root / "source.tsx"
            output_png = root / "highlighted.png"
            output_tsx = root / "highlighted.tsx"
            source = Image.new("RGBA", (32, 32), (90, 80, 40, 255))
            mask = Image.new("RGBA", (32, 32), (90, 80, 40, 255))
            for y in range(10, 22):
                for x in range(10, 22):
                    source.putpixel((x, y), (40, 100, 90, 255))
                    mask.putpixel((x, y), (40, 112, 144, 255))
            source.save(source_png)
            mask.save(mask_png)
            source_tsx.write_text(
                '<tileset name="ERWBET" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '<tile id="0"><animation><frame tileid="0" duration="120"/></animation></tile>'
                '<wangsets><wangset name="Water" type="corner" tile="0">'
                '<wangcolor name="Water" color="#00ffff" tile="0" probability="1"/>'
                '<wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>'
                '</wangset></wangsets></tileset>',
                encoding="utf-8",
            )

            build_erw_water_edge_highlight(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    water_mask_atlas=mask_png,
                    edge_highlight_px=1,
                    edge_highlight_strength=0.2,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="ERWBET highlighted water",
                )
            )

            output = Image.open(output_png).convert("RGBA")
            self.assertGreater(sum(output.getpixel((10, 16))[:3]), sum(source.getpixel((10, 16))[:3]))
            self.assertEqual(output.getpixel((16, 16)), source.getpixel((16, 16)))
            self.assertEqual(output.getpixel((9, 16)), source.getpixel((9, 16)))
            adapted_xml = ET.parse(output_tsx).getroot()
            self.assertEqual(len(adapted_xml.findall("tile/animation")), 1)

    def test_erw_ground_outline_builds_a_thin_opaque_border_and_preserves_wang_data(self) -> None:
        self.assertTrue(hasattr(builder, "build_erw_ground_outline"))
        build_erw_ground_outline = getattr(builder, "build_erw_ground_outline")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            texture_png = root / "texture.png"
            source_tsx = root / "source.tsx"
            output_png = root / "outlined.png"
            output_tsx = root / "outlined.tsx"
            source = Image.new("RGBA", (32, 32))
            for y in range(8, 24):
                for x in range(8, 24):
                    source.putpixel((x, y), (204, 148, 74, 255))
            source.save(source_png)
            Image.new("RGBA", (32, 32), (204, 148, 74, 255)).save(texture_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '<wangsets><wangset name="Ground" type="corner" tile="0">'
                '<wangcolor name="Ground" color="#ff0000" tile="0" probability="1"/>'
                '<wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>'
                '</wangset></wangsets></tileset>',
                encoding="utf-8",
            )

            build_erw_ground_outline(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    texture_atlas=texture_png,
                    texture_columns=1,
                    texture_tile_id=0,
                    border_width=3,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="ERW outlined ground",
                )
            )

            output = Image.open(output_png).convert("RGBA")
            self.assertEqual(output.getpixel((16, 16)), (204, 148, 74, 255))
            self.assertEqual(output.getpixel((6, 16))[3], 255)
            self.assertGreater(output.getpixel((4, 16))[1], output.getpixel((4, 16))[0])
            self.assertEqual(output.getpixel((2, 16))[3], 0)
            adapted_xml = ET.parse(output_tsx).getroot()
            self.assertEqual(len(adapted_xml.findall("wangsets/wangset/wangtile")), 1)

    def test_erw_ground_outline_can_tune_the_interior_texture(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            texture_png = root / "texture.png"
            source_tsx = root / "source.tsx"
            output_png = root / "outlined.png"
            output_tsx = root / "outlined.tsx"
            Image.new("RGBA", (32, 32), (204, 148, 74, 255)).save(source_png)
            Image.new("RGBA", (32, 32), (204, 148, 74, 255)).save(texture_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '</tileset>',
                encoding="utf-8",
            )

            builder.build_erw_ground_outline(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    texture_atlas=texture_png,
                    texture_columns=1,
                    texture_tile_id=0,
                    texture_hue_shift_degrees=6.5,
                    texture_saturation=0.96,
                    texture_brightness=0.5,
                    border_width=3,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="ERW tuned ground",
                )
            )

            output = Image.open(output_png).convert("RGBA")
            self.assertLess(max(output.getpixel((16, 16))[:3]), 120)

    def test_erw_ground_outline_can_preserve_the_source_material(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            texture_png = root / "texture.png"
            source_tsx = root / "source.tsx"
            output_png = root / "outlined.png"
            output_tsx = root / "outlined.tsx"
            source_color = (190, 130, 60, 255)
            Image.new("RGBA", (32, 32), source_color).save(source_png)
            Image.new("RGBA", (32, 32), (204, 148, 74, 255)).save(texture_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '</tileset>',
                encoding="utf-8",
            )

            builder.build_erw_ground_outline(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    texture_atlas=texture_png,
                    texture_columns=1,
                    texture_tile_id=0,
                    preserve_source_material=True,
                    material_expand_px=0,
                    border_width=2,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="ERW preserved ground",
                )
            )

            output = Image.open(output_png).convert("RGBA")
            self.assertEqual(output.getpixel((16, 16)), source_color)

    def test_erw_ground_outline_can_close_internal_material_holes_without_expanding_the_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            texture_png = root / "texture.png"
            source_tsx = root / "source.tsx"
            output_png = root / "outlined.png"
            output_tsx = root / "outlined.tsx"
            source = Image.new("RGBA", (32, 32))
            for y in range(8, 24):
                for x in range(8, 24):
                    source.putpixel((x, y), (190, 130, 60, 255))
            source.putpixel((16, 16), (80, 160, 60, 255))
            source.save(source_png)
            texture_color = (204, 148, 74, 255)
            Image.new("RGBA", (32, 32), texture_color).save(texture_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '</tileset>',
                encoding="utf-8",
            )

            builder.build_erw_ground_outline(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    texture_atlas=texture_png,
                    texture_columns=1,
                    texture_tile_id=0,
                    preserve_source_material=True,
                    material_close_px=1,
                    material_expand_px=0,
                    border_width=2,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="ERW closed ground",
                )
            )

            output = Image.open(output_png).convert("RGBA")
            self.assertEqual(output.getpixel((16, 16)), texture_color)
            self.assertEqual(output.getpixel((5, 16))[3], 0)

    def test_erw_ground_palette_can_be_tuned_without_changing_grass(self) -> None:
        sand = (178, 147, 105, 255)
        grass = (90, 160, 46, 255)

        tuned = adapt_erw_ground_pixel(
            sand,
            target_hue=0.113,
            saturation_factor=0.98,
            minimum_saturation=0.0,
            maximum_saturation=1.0,
            brightness_factor=0.975,
        )

        self.assertNotEqual(tuned, sand)
        self.assertEqual(adapt_erw_ground_pixel(grass), grass)

    def test_adjust_texture_hsv_changes_hue_saturation_and_brightness(self) -> None:
        source = Image.new("RGBA", (1, 1), (80, 140, 180, 255))

        result = adjust_texture_hsv(source, 18.0, 1.25, 0.8)

        self.assertNotEqual(result.getpixel((0, 0)), source.getpixel((0, 0)))
        self.assertLess(max(result.getpixel((0, 0))[:3]), max(source.getpixel((0, 0))[:3]))
        self.assertEqual(result.getpixel((0, 0))[3], 255)

    def test_erw_ground_preserves_native_wang_data_and_adapts_sand(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            source_tsx = root / "source.tsx"
            output_png = root / "adapted.png"
            output_tsx = root / "adapted.tsx"
            source = Image.new("RGBA", (32, 32), (178, 147, 105, 255))
            source.putpixel((0, 0), (90, 160, 46, 255))
            source.save(source_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '<wangsets><wangset name="Sand" type="corner" tile="0">'
                '<wangcolor name="Sand" color="#ff0000" tile="0" probability="1"/>'
                '<wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>'
                '</wangset></wangsets></tileset>',
                encoding="utf-8",
            )

            columns, rows, tile_count = build_erw_ground(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Aohara ground",
                )
            )

            self.assertEqual((columns, rows, tile_count), (1, 1, 1))
            adapted = Image.open(output_png).convert("RGBA")
            self.assertGreater(adapted.getpixel((16, 16))[0], 178)
            self.assertLess(adapted.getpixel((16, 16))[2], 105)
            self.assertEqual(adapted.getpixel((0, 0)), (90, 160, 46, 255))
            adapted_xml = ET.parse(output_tsx).getroot()
            self.assertEqual(adapted_xml.find("image").attrib["source"], "adapted.png")
            self.assertEqual(adapted_xml.find("wangsets/wangset").attrib["type"], "corner")
            self.assertEqual(len(adapted_xml.findall("wangsets/wangset/wangtile")), 1)

    def test_erw_ground_can_retune_grass_edges_to_match_the_terrain(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            source_tsx = root / "source.tsx"
            output_png = root / "adapted.png"
            output_tsx = root / "adapted.tsx"
            source = Image.new("RGBA", (32, 32), (178, 147, 105, 255))
            source.putpixel((0, 0), (75, 175, 74, 255))
            source.save(source_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '</tileset>',
                encoding="utf-8",
            )

            build_erw_ground(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    ground_hue=0.117,
                    ground_saturation=1.3,
                    ground_minimum_saturation=0.45,
                    ground_maximum_saturation=0.68,
                    ground_brightness=1.1,
                    grass_hue=0.226,
                    grass_saturation=1.35,
                    grass_minimum_saturation=0.68,
                    grass_maximum_saturation=0.86,
                    grass_brightness=0.82,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Aohara ERW terrain and dirt",
                )
            )

            adapted = Image.open(output_png).convert("RGBA")
            grass = adapted.getpixel((0, 0))
            self.assertGreater(grass[0], 75)
            self.assertLess(grass[1], 175)
            self.assertLess(grass[2], 74)
            self.assertNotEqual(adapted.getpixel((16, 16)), source.getpixel((16, 16)))

    def test_erw_water_preserves_native_wang_data_and_adapts_palette(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            source_tsx = root / "source.tsx"
            output_png = root / "adapted.png"
            output_tsx = root / "adapted.tsx"
            source = Image.new("RGBA", (32, 32), (40, 112, 144, 255))
            source.putpixel((0, 0), (190, 120, 80, 255))
            source.save(source_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '<wangsets><wangset name="Water" type="corner" tile="0">'
                '<wangcolor name="Water" color="#00ffff" tile="0" probability="1"/>'
                '<wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>'
                '</wangset></wangsets></tileset>',
                encoding="utf-8",
            )

            columns, rows, tile_count = build_erw_water(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Aohara water",
                )
            )

            self.assertEqual((columns, rows, tile_count), (1, 1, 1))
            adapted = Image.open(output_png).convert("RGBA")
            self.assertLess(adapted.getpixel((16, 16))[2], 144)
            self.assertLess(adapted.getpixel((0, 0))[0], 190)
            adapted_xml = ET.parse(output_tsx).getroot()
            self.assertEqual(adapted_xml.find("image").attrib["source"], "adapted.png")
            self.assertEqual(adapted_xml.find("wangsets/wangset").attrib["type"], "corner")
            self.assertEqual(len(adapted_xml.findall("wangsets/wangset/wangtile")), 1)

    def test_erw_water_can_retune_native_water_and_grass_edges_together(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            source_tsx = root / "source.tsx"
            output_png = root / "adapted.png"
            output_tsx = root / "adapted.tsx"
            source = Image.new("RGBA", (32, 32), (70, 169, 213, 255))
            source.putpixel((0, 0), (75, 175, 74, 255))
            source.save(source_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '</tileset>',
                encoding="utf-8",
            )

            build_erw_water(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    water_hue=0.458,
                    water_saturation=0.86,
                    water_minimum_saturation=0.48,
                    water_maximum_saturation=0.68,
                    water_brightness=0.53,
                    grass_hue=0.226,
                    grass_saturation=1.35,
                    grass_minimum_saturation=0.68,
                    grass_maximum_saturation=0.86,
                    grass_brightness=0.82,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Aohara ERW water and bank",
                )
            )

            adapted = Image.open(output_png).convert("RGBA")
            water = adapted.getpixel((16, 16))
            grass = adapted.getpixel((0, 0))
            self.assertLess(max(water[:3]), 130)
            self.assertGreater(grass[0], 75)
            self.assertLess(grass[1], 175)
            self.assertLess(grass[2], 74)

    def test_erw_water_can_strip_native_animation_for_a_ground_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            source_tsx = root / "source.tsx"
            output_png = root / "ground.png"
            output_tsx = root / "ground.tsx"
            Image.new("RGBA", (32, 32), (40, 112, 144, 255)).save(source_png)
            source_tsx.write_text(
                '<tileset name="ERWBET" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '<tile id="0"><animation><frame tileid="0" duration="120"/></animation></tile>'
                '<wangsets><wangset name="Water" type="corner" tile="0">'
                '<wangcolor name="Water" color="#00ffff" tile="0" probability="1"/>'
                '<wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>'
                '</wangset></wangsets></tileset>',
                encoding="utf-8",
            )

            build_erw_water(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="ERW ground",
                    strip_animations=True,
                )
            )

            adapted_xml = ET.parse(output_tsx).getroot()
            self.assertEqual(adapted_xml.findall("tile/animation"), [])
            self.assertEqual(len(adapted_xml.findall("wangsets/wangset/wangtile")), 1)

    def test_erw_water_can_expand_replacement_texture_into_the_native_bank(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            texture_png = root / "texture.png"
            source_tsx = root / "source.tsx"
            output_png = root / "ground.png"
            output_tsx = root / "ground.tsx"
            source = Image.new("RGBA", (32, 32), (80, 160, 60, 255))
            source.putpixel((16, 16), (40, 112, 144, 255))
            source.save(source_png)
            Image.new("RGBA", (32, 32), (204, 148, 74, 255)).save(texture_png)
            source_tsx.write_text(
                '<tileset name="ERWBET" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '<wangsets><wangset name="Water" type="corner" tile="0">'
                '<wangcolor name="Water" color="#00ffff" tile="0" probability="1"/>'
                '<wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>'
                '</wangset></wangsets></tileset>',
                encoding="utf-8",
            )

            build_erw_water(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    water_texture_atlas=texture_png,
                    water_texture_columns=1,
                    water_texture_tile_id=0,
                    water_expand_px=2,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="ERW ground",
                )
            )

            output = Image.open(output_png).convert("RGBA")
            self.assertGreater(output.getpixel((17, 16))[0], output.getpixel((17, 16))[1])
            self.assertLess(output.getpixel((20, 16))[0], output.getpixel((20, 16))[1])

    def test_erw_water_inner_shadow_stays_inside_native_water_boundary(self) -> None:
        source = Image.new("RGBA", (32, 32), (40, 112, 144, 255))
        source.paste((190, 120, 80, 255), (0, 0, 4, 32))
        adapted = source.copy()

        result = apply_erw_water_inner_shadow(adapted, source, 2, 0.3)

        self.assertEqual(result.getpixel((3, 16)), (190, 120, 80, 255))
        self.assertLess(result.getpixel((4, 16))[2], adapted.getpixel((4, 16))[2])
        self.assertEqual(result.getpixel((16, 16)), adapted.getpixel((16, 16)))

    def test_erw_water_retune_changes_only_pixels_selected_by_native_mask(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source_png = root / "source.png"
            mask_png = root / "mask.png"
            source_tsx = root / "source.tsx"
            output_png = root / "retuned.png"
            output_tsx = root / "retuned.tsx"
            source = Image.new("RGBA", (32, 32), (80, 140, 180, 255))
            source.paste((170, 120, 70, 255), (0, 0, 8, 32))
            source.save(source_png)
            mask = Image.new("RGBA", (32, 32), (40, 112, 144, 255))
            mask.paste((190, 120, 80, 255), (0, 0, 8, 32))
            mask.save(mask_png)
            source_tsx.write_text(
                '<tileset name="ERW" tilewidth="32" tileheight="32" tilecount="1" columns="1">'
                '<image source="source.png" width="32" height="32"/>'
                '<wangsets><wangset name="Water" type="corner" tile="0">'
                '<wangcolor name="Water" color="#00ffff" tile="0" probability="1"/>'
                '<wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>'
                '</wangset></wangsets></tileset>',
                encoding="utf-8",
            )

            build_erw_water_retune(
                Namespace(
                    source_atlas=source_png,
                    source_tsx=source_tsx,
                    water_mask_atlas=mask_png,
                    water_hue_shift_degrees=3.6,
                    water_saturation=1.25,
                    water_brightness=0.88,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Retuned water",
                )
            )

            retuned = Image.open(output_png).convert("RGBA")
            self.assertEqual(retuned.getpixel((4, 16)), source.getpixel((4, 16)))
            self.assertNotEqual(retuned.getpixel((16, 16)), source.getpixel((16, 16)))
            self.assertLess(max(retuned.getpixel((16, 16))[:3]), max(source.getpixel((16, 16))[:3]))
            self.assertEqual(ET.parse(output_tsx).getroot().find("wangsets/wangset").attrib["type"], "corner")

    def test_water_shoreline_is_baked_on_the_water_side_only(self) -> None:
        tile = Image.new("RGBA", (32, 32), (40, 120, 130, 255))
        tile.paste((120, 90, 40, 255), (0, 0, 4, 32))

        result = apply_water_shoreline(tile)

        self.assertEqual(result.getpixel((3, 16)), (120, 90, 40, 255))
        self.assertEqual(result.getpixel((4, 16)), (112, 104, 56, 255))
        self.assertEqual(result.getpixel((16, 16)), (40, 120, 130, 255))

    def test_water_shoreline_keeps_full_water_tiles_seamless(self) -> None:
        tile = Image.new("RGBA", (32, 32), (40, 120, 130, 255))
        tile.paste((80, 110, 50, 255), (0, 0, 2, 32))

        result = apply_water_shoreline(tile, 15)

        self.assertEqual(result.tobytes(), tile.tobytes())

    def test_ground_builds_three_complete_edge16_variants(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "ground.png"
            correction = root / "correction.png"
            output_png = root / "ground-path.png"
            output_tsx = root / "ground-path.tsx"
            Image.new("RGBA", (96, 32), (204, 151, 67, 255)).save(source)
            Image.new("RGBA", (128, 128)).save(correction)

            columns, rows, tile_count = build_ground(
                Namespace(
                    source_atlas=source,
                    source_columns=3,
                    texture_tile_ids=[0, 1, 2],
                    correction_overlay=correction,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Ground path",
                    frame_duration_ms=120,
                )
            )

            self.assertEqual((columns, rows, tile_count), (8, 6, 48))
            atlas = Image.open(output_png).convert("RGBA")
            self.assertEqual(atlas.size, (256, 192))
            self.assertEqual(atlas.getpixel((3 * 32 + 16, 3 * 32 + 16))[3], 255)
            self.assertEqual(atlas.getpixel((3 * 32, 3 * 32))[3], 255)
            root_xml = ET.parse(output_tsx).getroot()
            wangset = root_xml.find("wangsets/wangset")
            self.assertEqual(wangset.attrib["type"], "edge")
            self.assertEqual(len(wangset.findall("wangtile")), 48)
            horizontal = next(tile for tile in wangset.findall("wangtile") if tile.attrib["tileid"] == "10")
            self.assertEqual(horizontal.attrib["wangid"], "0,0,1,0,0,0,1,0")

    def test_grass_fill_builds_seamless_corner_variants(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "grass.png"
            output_png = root / "grass-path.png"
            output_tsx = root / "grass-path.tsx"
            image = Image.new("RGBA", (64, 32), (72, 138, 38, 255))
            image.paste((92, 158, 52, 255), (32, 0, 64, 32))
            image.save(source)

            columns, rows, tile_count = build_grass_fill(
                Namespace(
                    source_atlas=source,
                    source_columns=2,
                    texture_tile_ids=[0, 1],
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Grass fill",
                    frame_duration_ms=120,
                )
            )

            self.assertEqual((columns, rows, tile_count), (8, 4, 32))
            atlas = Image.open(output_png).convert("RGBA")
            self.assertEqual(atlas.getpixel((7 * 32 + 16, 32 + 16)), (72, 138, 38, 255))
            self.assertEqual(atlas.getpixel((32 + 24, 2 * 32 + 24))[3], 0)
            root_xml = ET.parse(output_tsx).getroot()
            wangset = root_xml.find("wangsets/wangset")
            self.assertEqual(wangset.attrib["type"], "corner")
            self.assertEqual(len(wangset.findall("wangtile")), 30)

    def test_grass_fill_can_shift_a_seamless_source_into_variants(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "grass.png"
            output_png = root / "grass-path.png"
            output_tsx = root / "grass-path.tsx"
            image = Image.new("RGBA", (32, 32), (72, 138, 38, 255))
            image.putpixel((0, 0), (1, 2, 3, 255))
            image.save(source)

            build_grass_fill(
                Namespace(
                    source_atlas=source,
                    source_columns=1,
                    texture_tile_ids=[0, 0],
                    source_seamless=True,
                    shift_variants=True,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Grass fill",
                    frame_duration_ms=120,
                )
            )

            atlas = Image.open(output_png).convert("RGBA")
            self.assertEqual(atlas.getpixel((7 * 32, 32)), (1, 2, 3, 255))
            self.assertEqual(atlas.getpixel((7 * 32 + 7, 3 * 32 + 11)), (1, 2, 3, 255))

    def test_grass_fill_can_calibrate_texture_palette(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "grass.png"
            output_png = root / "grass-path.png"
            output_tsx = root / "grass-path.tsx"
            Image.new("RGBA", (32, 32), (255, 0, 0, 255)).save(source)

            build_grass_fill(
                Namespace(
                    source_atlas=source,
                    source_columns=1,
                    texture_tile_ids=[0],
                    source_seamless=True,
                    shift_variants=False,
                    hue_shift_degrees=120,
                    texture_saturation=1.0,
                    texture_brightness=1.0,
                    texture_contrast=1.0,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Grass fill",
                    frame_duration_ms=120,
                )
            )

            atlas = Image.open(output_png).convert("RGBA")
            self.assertEqual(atlas.getpixel((7 * 32 + 16, 32 + 16)), (0, 255, 0, 255))

    def test_sampled_ground_converts_semantic_geometry_to_edge16_tiles(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            render = root / "render.png"
            map_json = root / "map.json"
            output_png = root / "sampled.png"
            output_tsx = root / "sampled.tsx"
            output_cells_json = root / "cells.json"
            source = Image.new("RGBA", (96, 96), (40, 140, 45, 255))
            source.paste((210, 165, 78, 255), (32, 0, 64, 96))
            source.save(render)
            map_json.write_text(
                '{"size":{"width":3,"height":3},"layers":[{"id":"path","runtimeType":"smart_tile","field":{"semanticCells":[0,1,0,0,1,0,0,1,0]}}]}',
                encoding="utf-8",
            )

            columns, rows, tile_count = build_sampled_ground(
                Namespace(
                    render=render,
                    map_json=map_json,
                    layer_id="path",
                    variants=2,
                    derive_from_render=True,
                    minimum_path_coverage=0.5,
                    minimum_path_red=145,
                    path_red_over_green=18,
                    path_green_over_blue=35,
                    output_cells_json=output_cells_json,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Sampled path",
                    frame_duration_ms=120,
                )
            )

            self.assertEqual((columns, rows, tile_count), (8, 4, 32))
            atlas = Image.open(output_png).convert("RGBA")
            self.assertEqual(atlas.getpixel((5 * 32 + 16, 16)), (210, 165, 78, 255))
            self.assertEqual(len(ET.parse(output_tsx).getroot().findall("wangsets/wangset/wangtile")), 32)
            self.assertIn('"x": 1', output_cells_json.read_text(encoding="utf-8"))

    def test_water_bakes_banks_and_four_frame_animations(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "water.png"
            source_tsx = root / "water.tsx"
            bank = root / "bank.png"
            tone = root / "tone.png"
            output_png = root / "water-path.png"
            output_tsx = root / "water-path.tsx"
            source_image = Image.new("RGBA", (128, 32))
            for tile_id, color in enumerate(((20, 90, 110, 255), (22, 92, 112, 255), (24, 94, 114, 255), (26, 96, 116, 255))):
                source_image.paste(color, (tile_id * 32, 0, tile_id * 32 + 32, 32))
            source_image.save(source)
            source_tsx.write_text(
                '<tileset><tile id="0"><animation>'
                '<frame tileid="0" duration="100"/><frame tileid="1" duration="100"/>'
                '<frame tileid="2" duration="100"/><frame tileid="3" duration="100"/>'
                '</animation></tile></tileset>',
                encoding="utf-8",
            )
            bank_image = Image.new("RGBA", (128, 128))
            bank_image.putpixel((0, 0), (100, 80, 30, 255))
            bank_image.save(bank)
            Image.new("RGBA", (128, 128)).save(tone)

            columns, rows, tile_count = build_water(
                Namespace(
                    source_atlas=source,
                    source_columns=4,
                    source_tsx=source_tsx,
                    base_tile_ids=[0],
                    frame_count=4,
                    bank_overlay=bank,
                    tone_overlay=tone,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Water path",
                    frame_duration_ms=100,
                )
            )

            self.assertEqual((columns, rows, tile_count), (8, 8, 64))
            atlas = Image.open(output_png).convert("RGBA")
            self.assertEqual(atlas.getpixel((0, 0)), (100, 80, 30, 255))
            root_xml = ET.parse(output_tsx).getroot()
            self.assertEqual(len(root_xml.findall("tile")), 16)
            frames = root_xml.find("tile/animation").findall("frame")
            self.assertEqual([frame.attrib["tileid"] for frame in frames], ["0", "16", "32", "48"])

    def test_sampled_corner_preserves_corner_topology_and_variants(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            render = root / "render.png"
            map_json = root / "map.json"
            output_png = root / "sampled-corner.png"
            output_tsx = root / "sampled-corner.tsx"
            source = Image.new("RGBA", (64, 64), (40, 140, 45, 255))
            source.paste((210, 165, 78, 255), (0, 0, 32, 32))
            source.save(render)
            map_json.write_text(
                '{"size":{"width":2,"height":2},"layers":[{"id":"path","runtimeType":"smart_tile","field":{"kind":"corner","corners":[1,0,0,0,0,0,0,0,0]}}]}',
                encoding="utf-8",
            )

            columns, rows, tile_count = build_sampled_corner(
                Namespace(
                    render=render,
                    map_json=map_json,
                    layer_id="path",
                    variants=2,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Sampled corner path",
                    frame_duration_ms=120,
                )
            )

            self.assertEqual((columns, rows, tile_count), (8, 4, 32))
            root_xml = ET.parse(output_tsx).getroot()
            wangset = root_xml.find("wangsets/wangset")
            self.assertEqual(wangset.attrib["type"], "corner")
            self.assertEqual(len(wangset.findall("wangtile")), 30)
            north_west = next(tile for tile in wangset.findall("wangtile") if tile.attrib["tileid"] == "8")
            self.assertEqual(north_west.attrib["wangid"], "0,0,0,0,0,0,0,1")

    def test_sampled_corner_animated_keeps_banks_static_and_animates_water(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            render = root / "render.png"
            map_json = root / "map.json"
            output_png = root / "animated.png"
            output_tsx = root / "animated.tsx"
            texture = root / "texture.png"
            source = Image.new("RGBA", (64, 64))
            for y in range(32):
                for x in range(32):
                    source.putpixel((x, y), (40 + x, 120 + y, 130 + x // 2, 255))
            source.putpixel((0, 0), (120, 90, 40, 255))
            source.save(render)
            texture_image = Image.new("RGBA", (32, 32))
            for y in range(32):
                for x in range(32):
                    texture_image.putpixel((x, y), (35 + x, 125 + y, 140 + x // 2, 255))
            texture_image.save(texture)
            map_json.write_text(
                '{"size":{"width":2,"height":2},"layers":[{"id":"water","runtimeType":"smart_tile","field":{"kind":"corner","corners":[1,0,0,0,0,0,0,0,0]}}]}',
                encoding="utf-8",
            )

            columns, rows, tile_count = build_sampled_corner_animated(
                Namespace(
                    render=render,
                    map_json=map_json,
                    layer_id="water",
                    variants=1,
                    frame_count=4,
                    water_texture_atlas=texture,
                    water_texture_columns=1,
                    water_texture_tile_id=0,
                    water_texture_use_full_atlas=False,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Animated corner water",
                    frame_duration_ms=140,
                )
            )

            self.assertEqual((columns, rows, tile_count), (8, 8, 64))
            atlas = Image.open(output_png).convert("RGBA")
            self.assertNotEqual(atlas.getpixel((16, 48)), atlas.getpixel((16, 112)))
            frames = ET.parse(output_tsx).getroot().find("tile/animation").findall("frame")
            self.assertEqual([frame.attrib["tileid"] for frame in frames], ["0", "16", "32", "48"])

    def test_bank_builds_one_complete_transparent_edge16_path(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bank = root / "bank.png"
            tone = root / "tone.png"
            output_png = root / "bank-path.png"
            output_tsx = root / "bank-path.tsx"
            bank_image = Image.new("RGBA", (128, 128))
            bank_image.putpixel((0, 0), (100, 80, 30, 255))
            bank_image.save(bank)
            Image.new("RGBA", (128, 128)).save(tone)

            columns, rows, tile_count = build_bank(
                Namespace(
                    bank_overlay=bank,
                    tone_overlay=tone,
                    output_png=output_png,
                    output_tsx=output_tsx,
                    name="Water banks",
                    frame_duration_ms=120,
                )
            )

            self.assertEqual((columns, rows, tile_count), (8, 2, 16))
            self.assertEqual(Image.open(output_png).convert("RGBA").getpixel((0, 0)), (100, 80, 30, 255))
            wangtiles = ET.parse(output_tsx).getroot().findall("wangsets/wangset/wangtile")
            self.assertEqual(len(wangtiles), 16)


if __name__ == "__main__":
    unittest.main()
