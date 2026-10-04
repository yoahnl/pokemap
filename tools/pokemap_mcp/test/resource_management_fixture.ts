import { canonicalPokemonConfig } from "./pokemon_fixture.js";

export function resourceManagementFixture() {
  return {
    version: "v8", name: "Informations", maps: [],
    pokemon: canonicalPokemonConfig(),
    tilesetFolders: [{ id: "shared", name: "Images" }],
    tilesets: [{
      id: "sheet", name: "Planche", relativePath: "assets/source.png",
      folderId: "shared", sortOrder: 7,
      source: {
        kind: "regular_atlas", assetId: "image", pixelWidth: 64, pixelHeight: 64,
        tileWidth: 32, tileHeight: 32, tileProperties: [],
      },
      extensionData: { authored: "préservé" },
    }],
    elementCategories: [{ id: "shared", name: "Décors" }],
    elements: [{
      id: "decor", name: "Décor", tilesetId: "sheet", categoryId: "shared",
      frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }],
      tags: ["préservé"],
    }],
    smartTileCatalog: {
      formatVersion: 4, categories: [{ id: "shared", name: "Terrains" }],
      atlases: [{ id: "atlas", name: "Atlas", tilesetId: "sheet", columns: 2, rows: 2 }],
      materials: [{ id: "material", name: "Herbe", connectionGroupId: "ground" }],
      presets: [{
        id: "ground", name: "Sol", categoryId: "shared", usage: "terrain",
        topology: "uniform", templateHint: "simple", status: "published",
        coveragePolicy: "complete", coverageProfile: { mode: "template" },
        transformPolicy: {}, defaultMaterialId: "material", allowedMaterialIds: ["material"],
        rules: [{
          id: "base", centerMatch: { kind: "material", materialId: "material" },
          signature: {}, candidates: [{
            id: "base", parts: [{ source: {
              kind: "frame", frame: { atlasId: "atlas", column: 0, row: 0 },
            } }],
          }],
        }],
        tags: ["préservé"],
      }],
      drafts: [{
        id: "editing", targetPresetId: "ground", sourcePresetId: "ground",
        name: "Mon brouillon non publié", categoryId: "shared", usage: "terrain",
        lastStage: "usage",
      }],
    },
  };
}
