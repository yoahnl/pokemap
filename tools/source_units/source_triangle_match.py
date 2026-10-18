import math


def area(vertices, axes):
    return abs(sum(start[axes[0]] * end[axes[1]] - end[axes[0]] * start[axes[1]]
                   for start, end in zip(vertices, vertices[1:] + vertices[:1]))) / 2


def normal(triangle):
    a, b, c = triangle
    ab, ac = [[end[i] - a[i] for i in range(3)] for end in [b, c]]
    value = [ab[1] * ac[2] - ab[2] * ac[1], ab[2] * ac[0] - ab[0] * ac[2],
             ab[0] * ac[1] - ab[1] * ac[0]]
    length = math.sqrt(sum(v * v for v in value))
    return [v / length for v in value] if length > 1e-12 else None


def weights(point, triangle, axes):
    a, b, c = triangle
    x, y = axes
    denominator = (b[x] - a[x]) * (c[y] - a[y]) - (b[y] - a[y]) * (c[x] - a[x])
    u = ((point[x] - a[x]) * (c[y] - a[y]) - (point[y] - a[y]) * (c[x] - a[x])) / denominator
    v = ((b[x] - a[x]) * (point[y] - a[y]) - (b[y] - a[y]) * (point[x] - a[x])) / denominator
    return [1 - u - v, u, v]


def intersection(first, second, axes):
    polygon = first
    x, y = axes
    orientation = 1 if ((second[1][x] - second[0][x]) * (second[2][y] - second[0][y])
                         - (second[1][y] - second[0][y]) * (second[2][x] - second[0][x])) > 0 else -1
    for a, b in zip(second, second[1:] + second[:1]):
        def distance(vertex):
            return orientation * ((b[x] - a[x]) * (vertex[y] - a[y])
                                  - (b[y] - a[y]) * (vertex[x] - a[x]))
        if not polygon:
            break
        clipped = []
        previous = polygon[-1]
        previous_distance = distance(previous)
        for current in polygon:
            current_distance = distance(current)
            if (previous_distance >= 0) != (current_distance >= 0):
                progress = previous_distance / (previous_distance - current_distance)
                clipped.append([previous[i] + progress * (current[i] - previous[i])
                                for i in range(len(previous))])
            if current_distance >= 0:
                clipped.append(current)
            previous, previous_distance = current, current_distance
        polygon = clipped
    return polygon


def uv_equal(original, projected, mode, tolerance):
    differences = [a - b for a, b in zip(original, projected)]
    if mode == 'WRAP':
        shift = round(differences[0])
        return all(abs(value - shift) <= tolerance for value in differences)
    if mode == 'MIRROR':
        for values in [differences, [a + b for a, b in zip(original, projected)]]:
            shift = 2 * round(values[0] / 2)
            if all(abs(value - shift) <= tolerance for value in values):
                return True
        return False
    if mode == 'CLAMP':
        return all(abs(value) <= tolerance for value in differences)
    raise ValueError('Unrecognized source texture wrapping: ' + mode)


def covered_triangle(surface, triangle, target, tolerance):
    direction = normal(triangle)
    if direction is None:
        return True
    axes = [i for i in range(3) if i != max(range(3), key=lambda i: abs(direction[i]))]
    original_area = area(triangle, axes)
    covered_area = 0
    for candidate_surface, candidate in target:
        if (surface.material, surface.texture, surface.wraps, surface.opacity) != (
                candidate_surface.material, candidate_surface.texture,
                candidate_surface.wraps, candidate_surface.opacity):
            continue
        candidate_normal = normal(candidate)
        if candidate_normal is None or any(abs(a - b) > tolerance
                                            for a, b in zip(direction, candidate_normal)):
            continue
        polygon = intersection(triangle, candidate, axes)
        if len(polygon) < 3 or area(polygon, axes) < 1e-12:
            continue
        projected = [[sum(w * vertex[i] for w, vertex in zip(weights(point, candidate, axes), candidate))
                      for i in range(len(point))] for point in polygon]
        if any(abs(point[i] - other[i]) > tolerance
               for point, other in zip(polygon, projected) for i in [0, 1, 2, 5, 6, 7]):
            continue
        if not all(uv_equal([p[3 + axis] for p in polygon], [p[3 + axis] for p in projected], mode, tolerance)
                   for axis, mode in enumerate(surface.wraps)):
            continue
        covered_area += area(polygon, axes)
    return abs(covered_area - original_area) <= tolerance * max(1, original_area)


def source_triangles_match(first, second, tolerance=1e-6):
    return bool(first and second) and all(covered_triangle(surface, triangle, target, tolerance)
                                         for source, target in [(first, second), (second, first)]
                                         for surface, triangle in source)

