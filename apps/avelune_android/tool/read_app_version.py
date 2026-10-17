import re
import sys
from pathlib import Path


def read_app_version(configuration):
    source = configuration.read_text(encoding="utf-8")
    match = re.fullmatch(r"\s*MARKETING_VERSION\s*=\s*([0-9]+\.[0-9]+\.[0-9]+)\s*", source)
    if match is None:
        raise ValueError(f"{configuration} must define a single numeric MARKETING_VERSION (x.y.z).")
    return match.group(1)


if __name__ == "__main__":
    shared_configuration = Path(__file__).resolve().parents[2] / "avelune_version.xcconfig"
    configuration = Path(sys.argv[1]) if len(sys.argv) > 1 else shared_configuration
    print(read_app_version(configuration))
