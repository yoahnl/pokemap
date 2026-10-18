from hashlib import sha256
from pathlib import Path
import re


def unique_source(root, name, suffix, expected=None):
    if not isinstance(name, str) or not re.fullmatch(r'[A-Za-z0-9_-]+', name):
        raise ValueError('Unsafe source resource name')
    if not isinstance(suffix, str) or not re.fullmatch(r'\.[A-Za-z0-9]+', suffix):
        raise ValueError('Unsafe source resource suffix')
    root = Path(root).resolve(strict=True)
    candidates = [path for path in root.glob(name + '*' + suffix)
                  if path.name == name + suffix or re.fullmatch(
                      re.escape(name) + r'\.\d+' + re.escape(suffix), path.name)]
    groups = {}
    for path in candidates:
        if path.is_symlink() or not path.is_file():
            raise ValueError('Source resource must be a regular file')
        value = sha256(path.read_bytes()).hexdigest()
        if expected is None or value == expected:
            groups.setdefault(value, []).append(path)
    if len(groups) != 1:
        raise ValueError('Expected one unambiguous source digest')
    value, paths = next(iter(groups.items()))
    return min(paths, key=lambda path: (len(path.name), path.name)), value
