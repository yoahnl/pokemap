import 'package:flutter/widgets.dart';

class AveluneWordmark extends StatelessWidget {
  const AveluneWordmark({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/home/avelune_logo.png',
    height: height,
    semanticLabel: 'Avelune Studio',
    filterQuality: FilterQuality.medium,
  );
}
