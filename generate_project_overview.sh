#!/bin/bash

OUTPUT_FILE="project_overview.txt"

> "$OUTPUT_FILE"

should_exclude() {
    local path="$1"
    local base
    base="$(basename "$path")"

    [[ "$path" == *"/.git/"* ]] && return 0
    [[ "$path" == *"/.dart_tool/"* ]] && return 0
    [[ "$path" == *"/.idea/"* ]] && return 0
    [[ "$path" == *"/build/"* ]] && return 0
    [[ "$path" == *"/dist/"* ]] && return 0
    [[ "$path" == *"/node_modules/"* ]] && return 0
    [[ "$path" == *"/coverage/"* ]] && return 0
    [[ "$path" == *"/coverage-e2e/"* ]] && return 0
    [[ "$path" == *"/logs/"* ]] && return 0
    [[ "$path" == *"/migrations/"* ]] && return 0
    [[ "$path" == *"/android/"* ]] && return 0
    [[ "$path" == *"/ios/"* ]] && return 0
    [[ "$path" == *"/linux/"* ]] && return 0
    [[ "$path" == *"/macos/"* ]] && return 0
    [[ "$path" == *"/windows/"* ]] && return 0
    [[ "$path" == *"/web/"* ]] && return 0
    [[ "$path" == *"/assets/"* ]] && return 0
    [[ "$path" == *"/public/"* ]] && return 0
    [[ "$path" == *"/style/"* ]] && return 0

    [[ "$base" == ".DS_Store" ]] && return 0
    [[ "$base" == "pubspec.lock" ]] && return 0
    [[ "$base" == "package-lock.json" ]] && return 0
    [[ "$base" == *.iml ]] && return 0
    [[ "$base" == *.log ]] && return 0
    [[ "$base" == *.png ]] && return 0
    [[ "$base" == *.jpg ]] && return 0
    [[ "$base" == *.jpeg ]] && return 0
    [[ "$base" == *.gif ]] && return 0
    [[ "$base" == *.webp ]] && return 0
    [[ "$base" == *.svg ]] && return 0
    [[ "$base" == *.db ]] && return 0
    [[ "$base" == *.db-journal ]] && return 0
    [[ "$base" == *.env ]] && return 0
    [[ "$base" == ".env.example" ]] && return 0
    [[ "$base" == *.freezed.dart ]] && return 0
    [[ "$base" == *.g.dart ]] && return 0

    return 1
}

should_include_file() {
    local file="$1"
    local base
    base="$(basename "$file")"

    [[ "$base" == "pubspec.yaml" ]] && return 0
    [[ "$base" == "analysis_options.yaml" ]] && return 0
    [[ "$base" == "README.md" ]] && return 0
    [[ "$base" == "GEMINI.md" ]] && return 0
    [[ "$base" == "melos.yaml" ]] && return 0
    [[ "$base" == "dart_test.yaml" ]] && return 0

    [[ "$file" == *.dart ]] && return 0
    [[ "$file" == *.yaml ]] && return 0
    [[ "$file" == *.yml ]] && return 0
    [[ "$file" == *.json ]] && return 0
    [[ "$file" == *.md ]] && return 0

    return 1
}

generate_tree() {
    local current_dir="$1"
    local indent="$2"

    local entries=()
    while IFS= read -r entry; do
        entries+=("$entry")
    done < <(find "$current_dir" -mindepth 1 -maxdepth 1 | sort)

    for entry in "${entries[@]}"; do
        should_exclude "$entry" && continue

        if [ -d "$entry" ]; then
            if find "$entry" \( -type f -o -type d \) | while IFS= read -r sub; do
                should_exclude "$sub" && continue
                if [ -f "$sub" ] && should_include_file "$sub"; then
                    exit 1
                fi
            done; [ $? -eq 1 ]; then
                echo "${indent}|-- $(basename "$entry")" >> "$OUTPUT_FILE"
                generate_tree "$entry" "$indent    "
            fi
        elif [ -f "$entry" ]; then
            if should_include_file "$entry"; then
                echo "${indent}|-- $(basename "$entry")" >> "$OUTPUT_FILE"
            fi
        fi
    done
}

copy_file_contents() {
    local root="$1"

    while IFS= read -r file; do
        should_exclude "$file" && continue
        should_include_file "$file" || continue

        echo -e "\n------ Content of: ./${file#./} ------\n" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
        echo -e "\n" >> "$OUTPUT_FILE"
    done < <(find "$root" -type f | sort)
}

echo "------ Project Tree ------" >> "$OUTPUT_FILE"
generate_tree "." ""

echo -e "\n\n------ File Contents ------\n" >> "$OUTPUT_FILE"
copy_file_contents "."

echo "Project tree and file contents saved to $OUTPUT_FILE"