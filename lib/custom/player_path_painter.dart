import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PlayerIndicatorShape {
  const PlayerIndicatorShape();

  static const double _overloadPadding = 10;
  static const double _distanceBetweenTopBottomCenters = 80.0;

  static const Offset _topLobeCenter =
      Offset(0.0, -_distanceBetweenTopBottomCenters);

  // preview
  static const double _previewRatio = 16 / 9;
  static const double _previewWidth = 130.0;
  static const double _previewHeight = _previewWidth / _previewRatio;

  static void _addRect(Path path, Offset center) {
    final Rect rect = Rect.fromLTWH(center.dx - _previewWidth / 2,
        center.dy - _previewHeight / 2, _previewWidth, _previewHeight);
    path.addRect(rect);
  }

  void paint(
    Canvas canvas,
    Offset center,
    Paint paint,
    double scale,
    ui.Image? labelImage,
    TextPainter labelText,
    double textScaleFactor,
    Size sizeWithOverflow,
  ) {
    if (scale == 0.0) {
      return;
    }

    double width =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;

    double previewTransX;

    // check preview overload screen
    if ((center.dx + _previewWidth / 2) > width) {
      previewTransX = width - _previewWidth / 2 - _overloadPadding;
    } else if ((center.dx - _previewWidth / 2) < 0) {
      previewTransX = _previewWidth / 2 + _overloadPadding;
    } else {
      previewTransX = center.dx;
    }

    final double overallScale = scale * textScaleFactor;
    final double inverseTextScale =
        textScaleFactor != 0 ? 1.0 / textScaleFactor : 0.0;
    final double labelHalfWidth = labelText.width / 2.0;

    canvas.save();
    canvas.translate(previewTransX, center.dy);
    canvas.scale(overallScale, overallScale);

    final Path path = Path();

    _addRect(path, _topLobeCenter);
    canvas.drawPath(path, paint);

    //draw image preview
    if (labelImage != null) {
      var imgAspect = labelImage.width / labelImage.height;
      var scale = _previewRatio > imgAspect
          ? (_previewHeight / labelImage.height)
          : (_previewWidth / labelImage.width);

      var imageRect2 = Rect.fromLTWH(
          _topLobeCenter.dx - (labelImage.width * scale) / 2,
          _topLobeCenter.dy - _previewHeight / 2,
          labelImage.width * scale,
          labelImage.height * scale);

      canvas.drawImageRect(
          labelImage,
          Offset.zero & Size(labelImage.width * 1.0, labelImage.height * 1.0),
          imageRect2,
          paint);
    }

    //  draw duration text
    canvas.save();
    canvas.translate(0, -_distanceBetweenTopBottomCenters);
    canvas.scale(inverseTextScale, inverseTextScale);
    labelText.paint(
        canvas,
        Offset.zero -
            Offset(labelHalfWidth, -_distanceBetweenTopBottomCenters / 2.0));
    canvas.restore();
    canvas.restore();
  }
}
