from types import SimpleNamespace
import unittest

from tools.source_units.source_triangle_match import source_triangles_match


class SourceTriangleMatchTest(unittest.TestCase):
    def surface(self, mode='WRAP'):
        return SimpleNamespace(material='cliff', texture='cliff.png', wraps=[mode, mode], opacity=1)

    def triangle(self):
        return [[0, 0, 0, 0, 0, 1, 1, 1], [1, 0, 0, 1, 0, 1, 1, 1],
                [0, 1, 0, 0, 1, 1, 1, 1]]

    def test_repeat_phase_and_retriangulation_preserve_source_appearance(self):
        triangle = self.triangle()
        shifted = [[*p[:3], p[3] + 2, p[4] - 3, *p[5:]] for p in triangle]
        midpoint = [(shifted[1][i] + shifted[2][i]) / 2 for i in range(8)]
        self.assertTrue(source_triangles_match([(self.surface(), triangle)],
                        [(self.surface(), [shifted[0], shifted[1], midpoint]),
                         (self.surface(), [shifted[0], midpoint, shifted[2]])]))

    def test_texture_stretch_is_rejected_even_with_integer_vertex_phases(self):
        triangle = self.triangle()
        stretched = [[*p[:3], p[3] * 2, p[4], *p[5:]] for p in triangle]
        self.assertFalse(source_triangles_match([(self.surface(), triangle)],
                                               [(self.surface(), stretched)]))

    def test_geometry_color_texture_and_winding_changes_are_rejected(self):
        triangle = self.triangle()
        for axis in [2, 5]:
            changed = [list(p) for p in triangle]
            changed[1][axis] += .1
            self.assertFalse(source_triangles_match([(self.surface(), triangle)],
                                                   [(self.surface(), changed)]))
        other = self.surface()
        other.texture = 'water.png'
        self.assertFalse(source_triangles_match([(self.surface(), triangle)], [(other, triangle)]))
        self.assertFalse(source_triangles_match([(self.surface(), triangle)],
                                               [(self.surface(), list(reversed(triangle)))]))

    def test_missing_region_is_rejected(self):
        triangle = self.triangle()
        midpoint = [(triangle[1][i] + triangle[2][i]) / 2 for i in range(8)]
        self.assertFalse(source_triangles_match([(self.surface(), triangle)],
                                               [(self.surface(), [triangle[0], triangle[1], midpoint])]))

    def test_mirror_reflection_requires_even_period_and_clamp_preserves_uv(self):
        triangle = self.triangle()
        mirrored = [[*p[:3], -p[3] + 2, p[4], *p[5:]] for p in triangle]
        self.assertTrue(source_triangles_match([(self.surface('MIRROR'), triangle)],
                                              [(self.surface('MIRROR'), mirrored)]))
        self.assertFalse(source_triangles_match([(self.surface('CLAMP'), triangle)],
                                               [(self.surface('CLAMP'), mirrored)]))


if __name__ == '__main__':
    unittest.main()
