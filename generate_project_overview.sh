#!/bin/bash

# Variables
OUTPUT_FILE="project_overview.txt"

# Vérifier si le fichier existe et le vider si c'est le cas
if [ -f "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

# Fonction pour ajouter l'arborescence du projet
echo "Generating project tree..."

generate_tree() {
    local current_dir="$1"
    local indent="$2"

    for file in "$current_dir"/*; do
        # Exclure certains dossiers et fichiers
        if [[ "$file" == *"node_modules"* || "$file" == *"windows"* || "$file" == *"web"* || "$file" == *"linux"* || "$file" == *"macos"* || "$file" == *"build"* ||"$file" == *"migrations"* || "$file" == *"logs"* || "$file" == *"dist"* || "$file" == *"www"* || "$file" == *"coverage"* || "$file" == *"coverage-e2e"* ||  "$file" == *".env"* || "$file" == *".env.example"* || "$file" == *".idea"* || "$file" == *"package-lock.json"* || "$file" == *".DS_Store"* || "$file" == *".git"* || "$file" == *.sh || "$file" == *.txt || "$file" == *.png || "$file" == *.db || "$file" == *.db-journal || "$file" == *"assets"* || "$file" == *"public"* || "$file" == *"style"* ]]; then
            continue
        fi

        # Si c'est un dossier, afficher et appeler récursivement
        if [ -d "$file" ]; then
            echo "${indent}|-- $(basename "$file")" >> "$OUTPUT_FILE"
            generate_tree "$file" "$indent    "
        elif [ -f "$file" ]; then
            echo "${indent}|-- $(basename "$file")" >> "$OUTPUT_FILE"
        fi
    done
}

# Fonction pour copier le contenu des fichiers
echo "Copying file contents..."

copy_file_contents() {
    local current_dir="$1"

    for file in "$current_dir"/*; do
        # Exclure certains dossiers et fichiers
        if [[ "$file" == *"node_modules"* || "$file" == *"windows"* || "$file" == *"web"* || "$file" == *"linux"* || "$file" == *"macos"* || "$file" == *"build"* ||"$file" == *"migrations"* || "$file" == *"logs"* || "$file" == *"dist"* || "$file" == *"www"* || "$file" == *"coverage"* || "$file" == *"coverage-e2e"* ||  "$file" == *".env"* || "$file" == *".env.example"* || "$file" == *".idea"* || "$file" == *"package-lock.json"* || "$file" == *".DS_Store"* || "$file" == *".git"* || "$file" == *.sh || "$file" == *.txt || "$file" == *.png || "$file" == *.db || "$file" == *.db-journal || "$file" == *"assets"* || "$file" == *"public"* || "$file" == *"style"* ]]; then
            continue
        fi

        # Si c'est un fichier, ajouter son contenu
        if [ -f "$file" ]; then
            echo -e "\n------ Content of: $file ------\n" >> "$OUTPUT_FILE"
            cat "$file" >> "$OUTPUT_FILE"
            echo -e "\n\n" >> "$OUTPUT_FILE"
        elif [ -d "$file" ]; then
            copy_file_contents "$file"
        fi
    done
}

# Démarrer depuis le répertoire courant
echo "------ Project Tree ------" >> "$OUTPUT_FILE"
generate_tree "." ""

echo -e "\n\n------ File Contents ------\n" >> "$OUTPUT_FILE"
copy_file_contents "."

echo "Project tree and file contents saved to $OUTPUT_FILE"
