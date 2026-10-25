import 'package:flutter/material.dart';
import 'package:localsend_app/gen/assets.gen.dart';

class LocalSendLogo extends StatelessWidget {
  final bool withText;

  const LocalSendLogo({required this.withText});

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Assets.img.logo512.image(
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
    );

    if (withText) {
      return Column(
        children: [
          logo,
          const SizedBox(height: 14),
          const Text(
            'Local Transfer',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return logo;
    }
  }
}
