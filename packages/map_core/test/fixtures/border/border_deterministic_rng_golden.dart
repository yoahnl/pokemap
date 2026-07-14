const String borderRngPrefixHex = '626f726465725f726e675f7631';

const List<
    ({
      String name,
      String signedInt64,
      String preimageHex,
      String fnv1a64Hex,
      String firstUint64Hex,
    })> borderSignedInt64RngGoldenVectors = [
  (
    name: 'zero',
    signedInt64: '0',
    preimageHex: '626f726465725f726e675f763102000000080000000000000000',
    fnv1a64Hex: 'cd37842907a276a3',
    firstUint64Hex: 'edd52235277639f9',
  ),
  (
    name: 'negative one',
    signedInt64: '-1',
    preimageHex: '626f726465725f726e675f76310200000008ffffffffffffffff',
    fnv1a64Hex: '452a7146749f611b',
    firstUint64Hex: '63a41a5e4eba9452',
  ),
  (
    name: 'minimum signed int64',
    signedInt64: '-9223372036854775808',
    preimageHex: '626f726465725f726e675f763102000000088000000000000000',
    fnv1a64Hex: '4a9b08ae7f478723',
    firstUint64Hex: '0c1b947f7dbc4c67',
  ),
  (
    name: 'maximum signed int64',
    signedInt64: '9223372036854775807',
    preimageHex: '626f726465725f726e675f763102000000087fffffffffffffff',
    fnv1a64Hex: '8875fca8c756c19b',
    firstUint64Hex: '8100e6c60e96cedf',
  ),
];

const List<({String name, String stateHex, String firstUint64Hex})>
    borderRawStateRngGoldenVectors = [
  (
    name: 'zero state uses the specified fallback',
    stateHex: '0000000000000000',
    firstUint64Hex: '0d83b3e29a21487a',
  ),
  (
    name: 'one state',
    stateHex: '0000000000000001',
    firstUint64Hex: '47e4ce4b896cdd1d',
  ),
];

const String borderUtf8TuplePreimageHex = '626f726465725f726e675f7631'
    '010000000563c3b47465'
    '0100000004f09f8c8a';

const String borderAbCPreimageHex = '626f726465725f726e675f7631'
    '01000000026162'
    '010000000163';

const String borderABcPreimageHex = '626f726465725f726e675f7631'
    '010000000161'
    '01000000026263';
