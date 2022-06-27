import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'custom_path_painter.dart';

class SliderThumbImage extends SliderComponentShape {
  final ui.Image? image;

  SliderThumbImage(this.image);

  static const CustomPathPainter _pathPainter = CustomPathPainter();

  @override
  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete, {
    TextPainter? labelPainter,
    double? textScaleFactor,
  }) {
    return _pathPainter.getPreferredSize(labelPainter!, textScaleFactor!);
  }

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {

    final ColorTween enableColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.valueIndicatorColor,
    );

    _pathPainter.paint(
      context.canvas,
      center,
      Paint()..color = enableColor.evaluate(enableAnimation)!,
      activationAnimation.value,
      image,
      labelPainter,
      textScaleFactor,
      sizeWithOverflow,
      null,
    );
  }
}