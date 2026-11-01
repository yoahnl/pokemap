import 'dart:typed_data';

const maxBattleRecipeSoundBytes = 8 * 1024 * 1024;

void inspectBattleRecipeSound(Uint8List bytes, String mediaType) {
  if (bytes.isEmpty || bytes.length > maxBattleRecipeSoundBytes) {
    throw const FormatException('Battle recipe sound exceeds byte limit');
  }
  final valid = switch (mediaType) {
    'audio/wav' => _inspectWav(bytes),
    'audio/ogg' => _inspectOgg(bytes),
    'audio/mpeg' => _inspectMp3(bytes),
    _ => false,
  };
  if (!valid) throw const FormatException('Invalid battle recipe sound');
}

bool _matches(Uint8List bytes, int offset, String value) {
  if (offset < 0 || offset + value.length > bytes.length) return false;
  for (var i = 0; i < value.length; i++) {
    if (bytes[offset + i] != value.codeUnitAt(i)) return false;
  }
  return true;
}

bool _validMetadata(int rate, int channels, int samples) =>
    rate >= 8000 &&
    rate <= 192000 &&
    channels >= 1 &&
    channels <= 8 &&
    samples > 0 &&
    samples <= rate * 120;

bool _inspectWav(Uint8List bytes) {
  if (bytes.length < 12 ||
      !_matches(bytes, 0, 'RIFF') ||
      !_matches(bytes, 8, 'WAVE')) {
    return false;
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(4, Endian.little) + 8 != bytes.length) return false;
  int? rate, channels, alignment, byteRate;
  var audioBytes = 0;
  var offset = 12;
  while (offset < bytes.length) {
    if (offset + 8 > bytes.length) return false;
    final size = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    final end = start + size;
    if (end > bytes.length || end + (size & 1) > bytes.length) return false;
    if (_matches(bytes, offset, 'fmt ')) {
      if (rate != null || size < 16) return false;
      var format = data.getUint16(start, Endian.little);
      channels = data.getUint16(start + 2, Endian.little);
      rate = data.getUint32(start + 4, Endian.little);
      byteRate = data.getUint32(start + 8, Endian.little);
      alignment = data.getUint16(start + 12, Endian.little);
      final bits = data.getUint16(start + 14, Endian.little);
      if (format == 0xfffe) {
        if (size < 40 ||
            data.getUint16(start + 16, Endian.little) < 22 ||
            data.getUint16(start + 16, Endian.little) + 18 > size ||
            data.getUint16(start + 18, Endian.little) > bits ||
            !_matchesGuidSuffix(bytes, start + 28)) {
          return false;
        }
        format = data.getUint32(start + 24, Endian.little);
      }
      if (!{1, 3}.contains(format) ||
          bits == 0 ||
          bits % 8 != 0 ||
          (format == 3 && bits != 32 && bits != 64) ||
          alignment != channels * (bits ~/ 8) ||
          byteRate != rate * alignment) {
        return false;
      }
    } else if (_matches(bytes, offset, 'data')) {
      audioBytes += size;
    }
    offset = end + (size & 1);
  }
  return rate != null &&
      channels != null &&
      alignment != null &&
      alignment > 0 &&
      audioBytes % alignment == 0 &&
      _validMetadata(rate, channels, audioBytes ~/ alignment);
}

bool _matchesGuidSuffix(Uint8List bytes, int offset) {
  const suffix = [0, 0, 16, 0, 128, 0, 0, 170, 0, 56, 155, 113];
  if (offset + suffix.length > bytes.length) return false;
  for (var i = 0; i < suffix.length; i++) {
    if (bytes[offset + i] != suffix[i]) return false;
  }
  return true;
}

bool _validOpusHead(Uint8List packet) {
  if (packet.length < 19 ||
      !_matches(packet, 0, 'OpusHead') ||
      packet[8] == 0 ||
      packet[8] > 15 ||
      packet[9] == 0 ||
      packet[9] > 8) {
    return false;
  }
  final channels = packet[9];
  final mapping = packet[18];
  if (mapping == 0) return channels <= 2;
  if (mapping != 1 || packet.length < 21 + channels) return false;
  final streams = packet[19];
  final coupled = packet[20];
  if (streams == 0 || coupled > streams || streams + coupled > 255) {
    return false;
  }
  for (var i = 0; i < channels; i++) {
    final index = packet[21 + i];
    if (index != 255 && index >= streams + coupled) return false;
  }
  return true;
}

int? _opusPacketSamples(List<int> prefix) {
  if (prefix.isEmpty) return null;
  final toc = prefix[0];
  final config = toc >> 3;
  final frameSamples = config < 12
      ? const [480, 960, 1920, 2880][config & 3]
      : config < 16
          ? const [480, 960][config & 1]
          : const [120, 240, 480, 960][config & 3];
  final countCode = toc & 3;
  final frames = switch (countCode) {
    0 => 1,
    1 || 2 => 2,
    _ => prefix.length < 2 ? 0 : prefix[1] & 0x3f,
  };
  final samples = frameSamples * frames;
  return frames == 0 || samples > 5760 ? null : samples;
}

final _oggCrcTable = List<int>.generate(256, (index) {
  var value = index << 24;
  for (var i = 0; i < 8; i++) {
    value = ((value << 1) ^ ((value & 0x80000000) == 0 ? 0 : 0x04c11db7))
        .toUnsigned(32);
  }
  return value;
});

bool _oggChecksum(Uint8List bytes, int start, int end, int expected) {
  var checksum = 0;
  for (var i = start; i < end; i++) {
    final byte = i >= start + 22 && i < start + 26 ? 0 : bytes[i];
    checksum =
        ((checksum << 8) ^ _oggCrcTable[((checksum >>> 24) ^ byte) & 0xff])
            .toUnsigned(32);
  }
  return checksum == expected;
}

bool _inspectOgg(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  var offset = 0, page = 0, packets = 0, rate = 0, channels = 0, preSkip = 0;
  int? serial;
  var continued = false, ended = false;
  var codec = '';
  var finalSamples = 0, previousGranule = 0;
  final header = <int>[];
  final opusPrefix = <int>[];
  var opusSamples = 0;
  int? opusInitialGranule;
  while (offset < bytes.length) {
    if (ended) {
      if (bytes.length - offset > 4096 ||
          Uint8List.sublistView(bytes, offset).any((byte) => byte != 0)) {
        return false;
      }
      break;
    }
    if (offset + 27 > bytes.length ||
        !_matches(bytes, offset, 'OggS') ||
        bytes[offset + 4] != 0) {
      return false;
    }
    final flags = bytes[offset + 5];
    if ((flags & ~7) != 0 ||
        ((flags & 1) != 0) != continued ||
        ((flags & 2) != 0) != (page == 0)) {
      return false;
    }
    final pageSerial = data.getUint32(offset + 14, Endian.little);
    serial ??= pageSerial;
    if (pageSerial != serial ||
        data.getUint32(offset + 18, Endian.little) != page) {
      return false;
    }
    final count = bytes[offset + 26];
    final payload = offset + 27 + count;
    if (payload > bytes.length || count == 0) return false;
    var end = payload;
    for (var i = 0; i < count; i++) {
      end += bytes[offset + 27 + i];
    }
    if (end > bytes.length ||
        !_oggChecksum(
            bytes, offset, end, data.getUint32(offset + 22, Endian.little))) {
      return false;
    }
    var cursor = payload;
    var opusPagePackets = 0;
    for (var i = 0; i < count; i++) {
      final length = bytes[offset + 27 + i];
      if (packets < 3 && header.length < 64) {
        final available = 64 - header.length;
        header.addAll(bytes.sublist(
            cursor, cursor + (length < available ? length : available)));
      }
      if (codec == 'opus' && packets >= 2 && opusPrefix.length < 2) {
        for (var byte = 0; byte < length && opusPrefix.length < 2; byte++) {
          opusPrefix.add(bytes[cursor + byte]);
        }
      }
      cursor += length;
      continued = length == 255;
      if (!continued && packets < 3) {
        final packet = Uint8List.fromList(header);
        if (packets == 0) {
          if (packet.length >= 30 &&
              packet[0] == 1 &&
              _matches(packet, 1, 'vorbis') &&
              ByteData.sublistView(packet).getUint32(7, Endian.little) == 0 &&
              packet[29] == 1 &&
              (packet[28] & 15) >= 6 &&
              (packet[28] >> 4) <= 13 &&
              (packet[28] & 15) <= (packet[28] >> 4)) {
            codec = 'vorbis';
            channels = packet[11];
            rate = ByteData.sublistView(packet).getUint32(12, Endian.little);
          } else if (_validOpusHead(packet)) {
            codec = 'opus';
            channels = packet[9];
            rate = 48000;
            preSkip = ByteData.sublistView(packet).getUint16(10, Endian.little);
          } else {
            return false;
          }
        } else if (packets == 1 &&
            !(codec == 'vorbis'
                ? packet.isNotEmpty &&
                    packet[0] == 3 &&
                    _matches(packet, 1, 'vorbis')
                : _matches(packet, 0, 'OpusTags'))) {
          return false;
        } else if (packets == 2 &&
            codec == 'vorbis' &&
            !(packet.isNotEmpty &&
                packet[0] == 5 &&
                _matches(packet, 1, 'vorbis'))) {
          return false;
        }
        header.clear();
      }
      if (!continued && codec == 'opus' && packets >= 2) {
        final samples = _opusPacketSamples(opusPrefix);
        if (samples == null) return false;
        opusSamples += samples;
        opusPagePackets++;
        opusPrefix.clear();
      }
      if (!continued) packets++;
    }
    final granuleLow = data.getUint32(offset + 6, Endian.little);
    final granuleHigh = data.getUint32(offset + 10, Endian.little);
    final unknownGranule =
        granuleLow == 0xffffffff && granuleHigh == 0xffffffff;
    if (codec == 'opus' && opusPagePackets > 0) {
      if (unknownGranule) return false;
      final isEnd = (flags & 4) != 0;
      if (opusInitialGranule == null) {
        if (!isEnd && granuleLow < opusSamples) return false;
        opusInitialGranule =
            granuleLow > opusSamples ? granuleLow - opusSamples : 0;
      } else {
        final expected = opusInitialGranule + opusSamples;
        if (isEnd ? granuleLow > expected : granuleLow != expected) {
          return false;
        }
      }
    }
    if (!unknownGranule) {
      if (granuleHigh != 0 ||
          granuleLow < previousGranule ||
          (rate != 0 && granuleLow > rate * 120 + preSkip)) {
        return false;
      }
      previousGranule = granuleLow;
    }
    if ((flags & 4) != 0) {
      if (continued || unknownGranule) {
        return false;
      }
      finalSamples = granuleLow - preSkip;
      ended = true;
    }
    offset = end;
    page++;
  }
  return ended &&
      packets > (codec == 'vorbis' ? 3 : 2) &&
      _validMetadata(rate, channels, finalSamples);
}

bool _inspectMp3(Uint8List bytes) {
  var offset = 0;
  if (_matches(bytes, 0, 'ID3')) {
    if (bytes.length < 10 ||
        bytes[3] < 2 ||
        bytes[3] > 4 ||
        bytes.sublist(6, 10).any((byte) => byte > 127)) {
      return false;
    }
    final size =
        (bytes[6] << 21) | (bytes[7] << 14) | (bytes[8] << 7) | bytes[9];
    offset = 10 + size + (bytes[3] == 4 && (bytes[5] & 0x10) != 0 ? 10 : 0);
    if (offset > bytes.length) return false;
  }
  var end = bytes.length;
  if (end >= 128 && _matches(bytes, end - 128, 'TAG')) end -= 128;
  var samples = 0, frames = 0, sampleRate = 0, channels = 0;
  while (offset < end) {
    if (offset + 4 > end ||
        bytes[offset] != 0xff ||
        (bytes[offset + 1] & 0xe0) != 0xe0) {
      return false;
    }
    final version = (bytes[offset + 1] >> 3) & 3;
    final layer = (bytes[offset + 1] >> 1) & 3;
    final bitrateIndex = bytes[offset + 2] >> 4;
    final sampleIndex = (bytes[offset + 2] >> 2) & 3;
    if (version == 1 ||
        layer != 1 ||
        bitrateIndex == 0 ||
        bitrateIndex == 15 ||
        sampleIndex == 3) {
      return false;
    }
    final rates = version == 3
        ? const [44100, 48000, 32000]
        : version == 2
            ? const [22050, 24000, 16000]
            : const [11025, 12000, 8000];
    final bitrates = version == 3
        ? const [
            0,
            32,
            40,
            48,
            56,
            64,
            80,
            96,
            112,
            128,
            160,
            192,
            224,
            256,
            320
          ]
        : const [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];
    final rate = rates[sampleIndex];
    final frameChannels = bytes[offset + 3] >> 6 == 3 ? 1 : 2;
    if (frames > 0 && (sampleRate != rate || channels != frameChannels)) {
      return false;
    }
    sampleRate = rate;
    channels = frameChannels;
    final length =
        (version == 3 ? 144 : 72) * bitrates[bitrateIndex] * 1000 ~/ rate +
            ((bytes[offset + 2] >> 1) & 1);
    if (length < 4 || offset + length > end) return false;
    offset += length;
    samples += version == 3 ? 1152 : 576;
    frames++;
  }
  return frames >= 2 && _validMetadata(sampleRate, channels, samples);
}
