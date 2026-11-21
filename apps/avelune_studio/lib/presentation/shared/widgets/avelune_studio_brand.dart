import 'package:flutter/widgets.dart';

class AveluneStudioBrand extends StatelessWidget {
  const AveluneStudioBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Avelune Studio',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/home/avelune_symbol.png',
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Image.asset(
            'assets/home/avelune_logo.png',
            width: 184,
            height: 54,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ],
      ],
    ),
  );
}
