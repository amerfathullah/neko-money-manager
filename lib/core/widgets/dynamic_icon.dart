import 'package:flutter/material.dart';

class DynamicIcon extends StatelessWidget {
  final int? codePoint;
  final String? fontFamily;
  final String? fontPackage;
  final IconData? fallback;
  final Color? color;
  final double? size;

  const DynamicIcon({
    super.key,
    required this.codePoint,
    this.fontFamily,
    this.fontPackage,
    this.fallback,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? IconTheme.of(context).size ?? 24.0;
    final effectiveColor = color ?? IconTheme.of(context).color ?? Colors.black;

    if (codePoint == null) {
      if (fallback != null) {
        return Icon(fallback, color: effectiveColor, size: effectiveSize);
      }
      return SizedBox(width: effectiveSize, height: effectiveSize);
    }

    return Text(
      String.fromCharCode(codePoint!),
      style: TextStyle(
        inherit: false,
        color: effectiveColor,
        fontSize: effectiveSize,
        fontFamily: fontFamily,
        package: fontPackage,
      ),
    );
  }
}
