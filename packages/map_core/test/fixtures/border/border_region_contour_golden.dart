const List<String> canonicalContourGoldenRows = <String>[
  '##..',
  '#...',
  '...#',
  '..##',
];

const String canonicalContourGoldenSignature = 'landBoundary@0,0/72:'
    '0,0>1,0:east:0-7:straight|'
    '1,0>2,0:east:7-14:right|'
    '2,0>2,1:south:14-25:right|'
    '2,1>1,1:west:25-32:left|'
    '1,1>1,2:south:32-43:right|'
    '1,2>0,2:west:43-50:right|'
    '0,2>0,1:north:50-61:straight|'
    '0,1>0,0:north:61-72:right;'
    'landBoundary@21,22/72:'
    '3,2>4,2:east:0-7:right|'
    '4,2>4,3:south:7-18:straight|'
    '4,3>4,4:south:18-29:right|'
    '4,4>3,4:west:29-36:straight|'
    '3,4>2,4:west:36-43:right|'
    '2,4>2,3:north:43-54:right|'
    '2,3>3,3:east:54-61:left|'
    '3,3>3,2:north:61-72:right';
