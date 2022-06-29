import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PlayerIndicatorShape {
  const PlayerIndicatorShape();

  static const double _topLobeRadius = 16.0;

  static const double _bottomLobeRadius = 10.0;
  static const double _labelPadding = 8.0;
  static const double _distanceBetweenTopBottomCenters = 60.0;
  static const double _middleNeckWidth = 3.0;
  static const double _bottomNeckRadius = 4.5;

  static const double _rightBottomNeckCenterX =
      _middleNeckWidth / 2 + _bottomNeckRadius;
  static const Offset _topLobeCenter =
      Offset(0.0, -_distanceBetweenTopBottomCenters);

  // preview
  static const double _previewRatio = 16 / 9;
  static const double _previewWidth = 100.0;
  static const double _previewHeight = _previewWidth / _previewRatio;

  static void _addRect(Path path, Offset center) {
    final Rect rect =
        Rect.fromLTWH(center.dx - _previewWidth / 2, center.dy - _previewHeight / 2, _previewWidth, _previewHeight);

    path.addRect(rect);
  }

  double _getIdealOffset(
    double halfWidthNeeded,
    double scale,
    Offset center,
    double widthWithOverflow,
  ) {
    const double edgeMargin = 8.0;
    final Rect topLobeRect = Rect.fromLTWH(
      -_topLobeRadius - halfWidthNeeded,
      -_topLobeRadius - _distanceBetweenTopBottomCenters,
      2.0 * (_topLobeRadius + halfWidthNeeded),
      2.0 * _topLobeRadius,
    );

    final Offset topLeft = (topLobeRect.topLeft * scale) + center;
    final Offset bottomRight = (topLobeRect.bottomRight * scale) + center;
    double shift = 0.0;

    if (topLeft.dx < edgeMargin) {
      shift = edgeMargin - topLeft.dx;
    }

    final double endGlobal = widthWithOverflow;
    if (bottomRight.dx > endGlobal - edgeMargin) {
      shift = endGlobal - edgeMargin - bottomRight.dx;
    }

    shift = scale == 0.0 ? 0.0 : shift / scale;
    if (shift < 0.0) {
      shift = math.max(shift, -halfWidthNeeded);
    } else {
      shift = math.min(shift, halfWidthNeeded);
    }
    return shift;
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
    assert(!sizeWithOverflow.isEmpty);

    final double overallScale = scale * textScaleFactor;
    final double inverseTextScale =
        textScaleFactor != 0 ? 1.0 / textScaleFactor : 0.0;
    final double labelHalfWidth = labelText.width / 2.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(overallScale, overallScale);

    final double bottomNeckTriangleHypotenuse =
        _bottomNeckRadius + _bottomLobeRadius / overallScale;
    final double rightBottomNeckCenterY = -math.sqrt(
        math.pow(bottomNeckTriangleHypotenuse, 2) -
            math.pow(_rightBottomNeckCenterX, 2));

    final Path path = Path()
      ..moveTo(_middleNeckWidth / 2, rightBottomNeckCenterY);

    final double halfWidthNeeded = math.max(
      0.0,
      inverseTextScale * labelHalfWidth - (_topLobeRadius - _labelPadding),
    );

    final double shift = _getIdealOffset(
        halfWidthNeeded, overallScale, center, sizeWithOverflow.width);
    final double rightWidthNeeded = halfWidthNeeded + shift;

    print("MTHAI 1: $_topLobeCenter --- ${Offset(rightWidthNeeded, 0.0)}");

    _addRect(
        path, _topLobeCenter + Offset(rightWidthNeeded, 0.0));

    canvas.drawPath(path, paint);

    canvas.save();
    canvas.translate(shift, -_distanceBetweenTopBottomCenters);
    canvas.scale(inverseTextScale, inverseTextScale);

    if (labelImage != null) {
      var imgAspect = labelImage.width / labelImage.height;
      var scale = _previewRatio > imgAspect
          ? (_previewHeight / labelImage.height)
          : (_previewWidth / labelImage.width);

      var left = (_previewWidth - labelImage.width * scale) / 2;
      var top = (_previewHeight - labelImage.height * scale) / 2;
      var right = left + (labelImage.width * scale);
      var bottom = top + (labelImage.height * scale);
      var imageRect = Offset(left, top) & Size(right - left, bottom - top);

      canvas.drawImage(labelImage,
          Offset.zero - Offset(labelHalfWidth, labelImage.height / 2.0), paint);

      // canvas.drawImageRect(
      //     labelImage,
      //     Offset.zero - Offset(labelHalfWidth, labelImage.height / 2.0) &
      //         Size(labelImage.width * 1.0, labelImage.height * 1.0),
      //     imageRect,
      //     paint);
    }

    labelText.paint(
        canvas, Offset.zero - Offset(labelHalfWidth, - _distanceBetweenTopBottomCenters / 2.0));
    canvas.restore();
  }
}
