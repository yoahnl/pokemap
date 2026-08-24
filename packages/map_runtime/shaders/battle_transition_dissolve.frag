#version 460 core

// BETA-BAT-019 (lot shaders) — le threshold dissolve des pré-transitions de
// la référence. Parité avec `black_to_white.frag` (seuil = canal rouge) et
// `rbytrainer.frag` (seuil fin = rouge + vert/256), fusionnés derrière
// l'uniform uFine (0.0 ou 1.0) : chaque pixel de l'écran devient noir opaque
// quand son seuil, lu dans la texture, passe sous uT ; sinon transparent —
// la carte encore rendue dessous reste visible.

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uT;
uniform float uFine;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 texel = texture(uTexture, uv);
  float threshold = texel.r + texel.g * uFine / 256.0;
  fragColor = threshold < uT ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(0.0);
}
