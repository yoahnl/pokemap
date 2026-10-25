import 'dart:ui';

Image Function(Image) createFlutterImagePresenter() =>
    (source) => source.clone();
