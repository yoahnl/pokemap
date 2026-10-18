def placement_key(placement):
    return (placement['modelId'], *(round(placement['position'][axis], 7) for axis in ('x', 'y', 'z')),
            placement['rotationDegrees'] % 360)


def assigned_units(document, map_id):
    proof = document['sourceProof']['maps'][map_id]
    result = list(proof['explicitPlacements'])
    for feature in proof['features']:
        result.extend(feature['expectedPlacements'])
    return result


def reference_keys(placements):
    return {(row['group'], row['geometry'], row['material'], index) for placement in placements
            for row in placement['sourceReferences'] for index in row['triangleIndices']}
