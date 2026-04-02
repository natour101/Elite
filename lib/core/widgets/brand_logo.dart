import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.height = 42,
    this.showBag = false,
    this.withLabel = true,
  });

  final double height;
  final bool showBag;
  final bool withLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: height,
          height: height,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.black,
            borderRadius: BorderRadius.circular(height / 3),
          ),
          child: Image.asset(
            showBag ? AppAssets.shoppingBagLogo : AppAssets.storeLogo,
            fit: BoxFit.contain,
          ),
        ),
        if (withLabel) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ELITE',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
              ),
              Text(
                'Luxury Originals',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gold,
                      letterSpacing: 1.2,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
