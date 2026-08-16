enum AudioMediaFormat {
  ogg('.ogg', 'audio/ogg'),
  mp3('.mp3', 'audio/mpeg'),
  wav('.wav', 'audio/wav'),
  flac('.flac', 'audio/flac'),
  m4a('.m4a', 'audio/mp4'),
  aac('.aac', 'audio/aac');

  const AudioMediaFormat(this.extension, this.mediaType);

  final String extension;
  final String mediaType;
}

AudioMediaFormat? detectAudioMediaFormat(List<int> bytes) {
  if (_asciiAt(bytes, 0, 'OggS')) return AudioMediaFormat.ogg;
  if (_asciiAt(bytes, 0, 'RIFF') && _asciiAt(bytes, 8, 'WAVE')) {
    return AudioMediaFormat.wav;
  }
  if (_asciiAt(bytes, 0, 'fLaC')) return AudioMediaFormat.flac;
  if (_asciiAt(bytes, 4, 'ftyp')) return AudioMediaFormat.m4a;
  if (_asciiAt(bytes, 0, 'ID3') || _looksLikeMpegLayerThree(bytes)) {
    return AudioMediaFormat.mp3;
  }
  if (_looksLikeAacAdts(bytes)) return AudioMediaFormat.aac;
  return null;
}

AudioMediaFormat? audioMediaFormatForExtension(String extension) {
  final normalized = extension.trim().toLowerCase();
  for (final format in AudioMediaFormat.values) {
    if (format.extension == normalized) return format;
  }
  return null;
}

bool _looksLikeMpegLayerThree(List<int> bytes) {
  if (bytes.length < 2 || bytes[0] != 0xff || (bytes[1] & 0xe0) != 0xe0) {
    return false;
  }
  final versionBits = bytes[1] & 0x18;
  final layerBits = bytes[1] & 0x06;
  return versionBits != 0x08 && layerBits == 0x02;
}

bool _looksLikeAacAdts(List<int> bytes) =>
    bytes.length >= 2 && bytes[0] == 0xff && (bytes[1] & 0xf6) == 0xf0;

bool _asciiAt(List<int> bytes, int offset, String value) {
  if (offset < 0 || offset + value.length > bytes.length) return false;
  for (var index = 0; index < value.length; index++) {
    if (bytes[offset + index] != value.codeUnitAt(index)) return false;
  }
  return true;
}
