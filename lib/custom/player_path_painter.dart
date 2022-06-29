import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PlayerIndicatorShape {
  const PlayerIndicatorShape();

  static const double _overloadPadding = 10;

  static const double _topLobeRadius = 16.0;
  static const double _labelPadding = 8.0;
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
    double width =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;

    if (scale == 0.0) {
      return;
    }
    assert(!sizeWithOverflow.isEmpty);

    final double overallScale = scale * textScaleFactor;
    final double inverseTextScale =
        textScaleFactor != 0 ? 1.0 / textScaleFactor : 0.0;
    final double labelHalfWidth = labelText.width / 2.0;

    canvas.save();
    canvas.scale(overallScale, overallScale);

    // check preview overload screen
    if ((center.dx + _previewWidth / 2) > width) {
      canvas.translate(width - _previewWidth / 2 - _overloadPadding, center.dy);
    } else if ((center.dx - _previewWidth / 2) < 0) {
      canvas.translate(_previewWidth / 2 + _overloadPadding, center.dy);
    } else {
      canvas.translate(center.dx, center.dy);
    }

    final Path path = Path();
    final double halfWidthNeeded = math.max(
      0.0,
      inverseTextScale * labelHalfWidth - (_topLobeRadius - _labelPadding),
    );
    final double shift = _getIdealOffset(
        halfWidthNeeded, overallScale, center, sizeWithOverflow.width);

    _addRect(path, _topLobeCenter);
    canvas.drawPath(path, paint);

    //canvas image preview
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
