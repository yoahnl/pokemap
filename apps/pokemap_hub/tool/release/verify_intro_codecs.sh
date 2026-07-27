#!/usr/bin/env bash

set -euo pipefail

project_root="$(
  cd "$(/usr/bin/dirname "${BASH_SOURCE[0]}")/../.." &&
    pwd
)"
ffprobe_bin="${FFPROBE_BIN:-ffprobe}"

if ! command -v "$ffprobe_bin" >/dev/null 2>&1; then
  echo "ffprobe is required to verify intro codecs." >&2
  exit 69
fi

verify_fixture() {
  local label="$1"
  local relative_path="$2"
  local expected_width="$3"
  local expected_height="$4"
  local fixture="$project_root/$relative_path"

  if [[ ! -f "$fixture" ]]; then
    echo "Codec fixture is missing: $fixture" >&2
    exit 66
  fi

  local video_codec
  local pixel_format
  local width
  local height
  local audio_codec
  local audio_channels
  local audio_sample_rate
  local duration
  video_codec="$(
    "$ffprobe_bin" -v error -select_streams v:0 \
      -show_entries stream=codec_name \
      -of default=noprint_wrappers=1:nokey=1 \
      "$fixture"
  )"
  pixel_format="$(
    "$ffprobe_bin" -v error -select_streams v:0 \
      -show_entries stream=pix_fmt \
      -of default=noprint_wrappers=1:nokey=1 \
      "$fixture"
  )"
  width="$(
    "$ffprobe_bin" -v error -select_streams v:0 \
      -show_entries stream=width \
      -of default=noprint_wrappers=1:nokey=1 \
      "$fixture"
  )"
  height="$(
    "$ffprobe_bin" -v error -select_streams v:0 \
      -show_entries stream=height \
      -of default=noprint_wrappers=1:nokey=1 \
      "$fixture"
  )"
  audio_codec="$(
    "$ffprobe_bin" -v error -select_streams a:0 \
      -show_entries stream=codec_name \
      -of default=noprint_wrappers=1:nokey=1 \
      "$fixture"
  )"
  audio_channels="$(
    "$ffprobe_bin" -v error -select_streams a:0 \
      -show_entries stream=channels \
      -of default=noprint_wrappers=1:nokey=1 \
      "$fixture"
  )"
  audio_sample_rate="$(
    "$ffprobe_bin" -v error -select_streams a:0 \
      -show_entries stream=sample_rate \
      -of default=noprint_wrappers=1:nokey=1 \
      "$fixture"
  )"
  duration="$(
    "$ffprobe_bin" -v error \
      -show_entries format=duration \
      -of default=noprint_wrappers=1:nokey=1 \
      "$fixture"
  )"

  [[ "$video_codec" == 'h264' ]] || {
    echo "$label video codec is not H.264: $video_codec" >&2
    exit 65
  }
  [[ "$pixel_format" == 'yuv420p' ]] || {
    echo "$label pixel format is not yuv420p: $pixel_format" >&2
    exit 65
  }
  [[ "$width" == "$expected_width" && "$height" == "$expected_height" ]] || {
    echo "$label dimensions are ${width}x${height}." >&2
    exit 65
  }
  [[ "$audio_codec" == 'aac' ]] || {
    echo "$label audio codec is not AAC: $audio_codec" >&2
    exit 65
  }
  [[ "$audio_channels" == '2' && "$audio_sample_rate" == '48000' ]] || {
    echo "$label audio layout is ${audio_channels}ch at ${audio_sample_rate}Hz." >&2
    exit 65
  }
  /usr/bin/awk -v duration="$duration" 'BEGIN { exit !(duration > 1.0) }' || {
    echo "$label duration is too short: $duration" >&2
    exit 65
  }

  echo "${label}_codec_verified=true"
}

verify_fixture \
  landscape \
  assets/certification/intro_landscape_h264_aac.mp4 \
  320 \
  180
verify_fixture \
  portrait \
  assets/certification/intro_portrait_h264_aac.mp4 \
  180 \
  320
