STYLE_PROFILE_UNSET = object()
DEFAULT_CELL_SIZE = 32
SUPPORTED_CELL_SIZES = frozenset({16, 32, 48})


def require_cell_size(value):
    if isinstance(value, bool) or not isinstance(value, int) or value not in SUPPORTED_CELL_SIZES:
        raise ValueError("cellSizePx must be one of 16, 32 or 48")
    return value


def require_style_profile(value=STYLE_PROFILE_UNSET):
    if value is STYLE_PROFILE_UNSET:
        value = {"id": "project", "allowedProvenance": ["project", "custom"]}
    if not isinstance(value, dict) or set(value) != {"id", "allowedProvenance"}:
        raise ValueError("styleProfile requires only id and allowedProvenance")
    identifier = value["id"]
    allowed = value["allowedProvenance"]
    if not isinstance(identifier, str) or not identifier or identifier.strip() != identifier or len(identifier) > 128:
        raise ValueError("styleProfile.id must be a non-empty identifier")
    if not isinstance(allowed, list) or not 1 <= len(allowed) <= 64:
        raise ValueError("styleProfile.allowedProvenance must contain 1..64 identifiers")
    if any(not isinstance(item, str) or not item or item.strip() != item or len(item) > 128 for item in allowed):
        raise ValueError("styleProfile.allowedProvenance contains an invalid identifier")
    if len(set(allowed)) != len(allowed):
        raise ValueError("styleProfile.allowedProvenance must be unique")
    return {"id": identifier, "allowedProvenance": list(allowed)}
