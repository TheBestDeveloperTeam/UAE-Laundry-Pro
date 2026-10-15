import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/lottie/lottie_catalog.dart';
import 'package:lottie/lottie.dart';

class LaundryLottie extends StatelessWidget {
  const LaundryLottie({
    super.key,
    required this.logicalId,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String logicalId;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final binding = LottieCatalog.instance.resolve(logicalId);
    if (binding == null) {
      return const SizedBox.shrink();
    }
    final fit = binding.fit == 'cover' ? BoxFit.cover : BoxFit.contain;
    return Opacity(
      opacity: binding.opacity.clamp(0.0, 1.0),
      child: Lottie.asset(
        binding.assetPath,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        repeat: binding.repeat,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Subtle full-screen background motion (low opacity).
class LaundryLottieBackground extends StatelessWidget {
  const LaundryLottieBackground({
    super.key,
    required this.logicalId,
    this.child,
  });

  final String logicalId;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: LaundryLottie(
            logicalId: logicalId,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
