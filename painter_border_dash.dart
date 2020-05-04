import 'dart:ui' as dartUI;

import 'package:flutter/material.dart';

class DashedBorderPainter extends CustomPainter {
  double borderRadius;
  double strokeWidth;
  Color color;
  DashedBorderPainter({this.borderRadius = 2, this.strokeWidth = 1, this.color = Colors.black});
  @override
  void paint(Canvas canvas, Size size) {
    var p = Paint()
      ..color = color
      ..shader = dartUI.Gradient.linear(
          Offset(0, 0),
          Offset(4, 4),
          [color, Colors.transparent],
          [.3, .6],
          TileMode.repeated)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    var radius = Radius.circular(borderRadius);
    canvas.drawRRect(
        RRect.fromLTRBAndCorners(0, 0, size.width, size.height,
            topLeft: radius,
            topRight: radius,
            bottomLeft: radius,
            bottomRight: radius),
        p);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

