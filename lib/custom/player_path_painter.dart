import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PlayerIndicatorShape {
  const PlayerIndicatorShape();

  static const double _topLobeRadius = 16.0;
  static const double _minLabelWidth = 16.0;

  static const double _bottomLobeRadius = 10.0;
  static const double _labelPadding = 8.0;
  static const double _distanceBetweenTopBottomCenters = 40.0;
  static const double _middleNeckWidth = 3.0;
  static const double _bottomNeckRadius = 4.5;

  static const double _neckTriangleBase = _topNeckRadius + _middleNeckWidth / 2;
  static const double _rightBottomNeckCenterX =
      _middleNeckWidth / 2 + _bottomNeckRadius;
  static const double _rightBottomNeckAngleStart = math.pi;
  static const Offset _topLobeCenter =
      Offset(0.0, -_distanceBetweenTopBottomCenters);
  static const double _topNeckRadius = 13.0;

  static const double _neckTriangleHypotenuse = _topLobeRadius + _topNeckRadius;

  static const double _twoSeventyDegrees = 3.0 * math.pi / 2.0;
  static const double _ninetyDegrees = math.pi / 2.0;
  static const double _thirtyDegrees = math.pi / 6.0;
  static const double _preferredHeight =
      _distanceBetweenTopBottomCenters + _topLobeRadius + _bottomLobeRadius;

  static void _addArc(Path path, Offset center, double radius,
      double startAngle, double endAngle) {
    assert(center.isFinite);
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    path.arcTo(arcRect, startAngle, endAngle - startAngle, false);
  }

  static void _addRect(Path path, Offset center) {
    final Rect arcRect = Rect.fromLTRB(center.dx - 100 /2, center.dy - 50 / 2, center.dx + 100 /2, center.dy + 50 / 2);
    path.addRect(arcRect);
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
    Color? strokePaintColor,
  ) {
    if (scale == 0.0) {
      return;
    }
    assert(!sizeWithOverflow.isEmpty);

    final double overallScale = scale * textScaleFactor;
    final double inverseTextScale =
        textScaleFactor != 0 ? 1.0 / textScaleFactor : 0.0;
    final double labelHalfWidth = labelImage != null
        ? labelImage.width.toDouble() / 2.0
        : labelText.width / 2.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(overallScale, overallScale);

    final double bottomNeckTriangleHypotenuse =
        _bottomNeckRadius + _bottomLobeRadius / overallScale;
    final double rightBottomNeckCenterY = -math.sqrt(
        math.pow(bottomNeckTriangleHypotenuse, 2) -
            math.pow(_rightBottomNeckCenterX, 2));
    final double rightBottomNeckAngleEnd =
        math.pi + math.atan(rightBottomNeckCenterY / _rightBottomNeckCenterX);

    final Path path = Path()
      ..moveTo(_middleNeckWidth / 2, rightBottomNeckCenterY);

    _addArc(
      path,
      Offset(_rightBottomNeckCenterX, rightBottomNeckCenterY),
      _bottomNeckRadius,
      _rightBottomNeckAngleStart,
      rightBottomNeckAngleEnd,
    );
    _addArc(
      path,
      Offset.zero,
      _bottomLobeRadius / overallScale,
      rightBottomNeckAngleEnd - math.pi,
      2 * math.pi - rightBottomNeckAngleEnd,
    );
    _addArc(
      path,
      Offset(-_rightBottomNeckCenterX, rightBottomNeckCenterY),
      _bottomNeckRadius,
      math.pi - rightBottomNeckAngleEnd,
      0,
    );

    final double halfWidthNeeded = math.max(
      0.0,
      inverseTextScale * labelHalfWidth - (_topLobeRadius - _labelPadding),
    );

    final double shift = _getIdealOffset(
        halfWidthNeeded, overallScale, center, sizeWithOverflow.width);
    final double leftWidthNeeded = halfWidthNeeded - shift;
    final double rightWidthNeeded = halfWidthNeeded + shift;

    final double leftAmount =
        math.max(0.0, math.min(1.0, leftWidthNeeded / _neckTriangleBase));
    final double rightAmount =
        math.max(0.0, math.min(1.0, rightWidthNeeded / _neckTriangleBase));
    final double leftTheta = (1.0 - leftAmount) * _thirtyDegrees;
    final double rightTheta = (1.0 - rightAmount) * _thirtyDegrees;
    final Offset leftTopNeckCenter = Offset(
      -_neckTriangleBase,
      _topLobeCenter.dy + math.cos(leftTheta) * _neckTriangleHypotenuse,
    );
    final Offset neckRightCenter = Offset(
      _neckTriangleBase,
      _topLobeCenter.dy + math.cos(rightTheta) * _neckTriangleHypotenuse,
    );
    final double leftNeckArcAngle = _ninetyDegrees - leftTheta;
    final double rightNeckArcAngle = math.pi + _ninetyDegrees - rightTheta;
    final double neckStretchBaseline = math.max(
        0.0,
        rightBottomNeckCenterY -
            math.max(leftTopNeckCenter.dy, neckRightCenter.dy));
    final double t = math.pow(inverseTextScale, 3.0) as double;
    final double stretch =
        (neckStretchBaseline * t).clamp(0.0, 10.0 * neckStretchBaseline);
    final Offset neckStretch = Offset(0.0, neckStretchBaseline - stretch);

    _addArc(
      path,
      leftTopNeckCenter + neckStretch,
      _topNeckRadius,
      0.0,
      -leftNeckArcAngle,
    );
    // _addArc(
    //   path,
    //   _topLobeCenter - Offset(leftWidthNeeded, 0.0) + neckStretch,
    //   _topLobeRadius,
    //   _ninetyDegrees + leftTheta,
    //   _twoSeventyDegrees,
    // );
    // _addArc(
    //   path,
    //   _topLobeCenter + Offset(rightWidthNeeded, 0.0) + neckStretch,
    //   _topLobeRadius,
    //   _twoSeventyDegrees,
    //   _twoSeventyDegrees + math.pi - rightTheta,
    // );

    _addRect(path, _topLobeCenter + Offset(rightWidthNeeded, 0.0) + neckStretch);
    _addArc(
      path,
      neckRightCenter + neckStretch,
      _topNeckRadius,
      rightNeckArcAngle,
      math.pi,
    );

    if (strokePaintColor != null) {
      final Paint strokePaint = Paint()
        ..color = strokePaintColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, strokePaint);
    }

    canvas.drawPath(path, paint);

    // Draw the label.
    canvas.save();
    canvas.translate(shift, -_distanceBetweenTopBottomCenters + neckStretch.dy);
    canvas.scale(inverseTextScale, inverseTextScale);

    if (labelImage != null) {
      // var canvasAspect = canvasSize.width / canvasSize.height;
      // var imgAspect = labelImage.width / labelImage.height;
      // var scale = canvasAspect > imgAspect
      //     ? (canvasSize.height / labelImage.height)
      //     : (canvasSize.width / labelImage.width);
      //
      // var left = ((canvasSize.width - labelImage.width * scale) / 2);
      // var top = ((canvasSize.height - labelImage.height * scale) / 2);
      // var right = left + (labelImage.width * scale);
      // var bottom = top + (labelImage.height * scale);
      // var imageRect = Offset(left, top) & Size(right - left, bottom - top);

      canvas.drawImage(labelImage,
          Offset.zero - Offset(labelHalfWidth, labelImage.height / 2.0), paint);
      // canvas.drawImageRect(
      //     labelImage,
      //     Offset(labelHalfWidth, labelImage.height / 2.0) & Size(labelImage.width * 1.0, labelImage.height * 1.0),
      //     imageRect,
      //     paint);
    } else {
      labelText.paint(
          canvas, Offset.zero - Offset(labelHalfWidth, labelText.height / 2.0));
    }

    canvas.restore();
    canvas.restore();
  }
}
