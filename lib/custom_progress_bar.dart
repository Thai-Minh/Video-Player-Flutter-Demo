import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef ThumbDragStartCallback = void Function(ThumbDragDetails details);

typedef ThumbDragUpdateCallback = void Function(ThumbDragDetails details);

enum ProgressBarShape {
  round,
  square,
}

class ProgressBar extends SingleChildRenderObjectWidget {
  const ProgressBar({
    Key? key,
    Widget? child,
    this.progress,
    this.total,
    this.buffered,
    this.onSeek,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.isDrawThumb,
    this.barHeight = 5.0,
    this.backgroundBarColor,
    this.progressBarColor,
    this.bufferedBarColor,
    this.progressBarShape = ProgressBarShape.round,
    this.thumbRadius = 5.0,
    this.thumbColor,
    this.thumbBlurColor,
    this.thumbScaleRadius = 10.0,
  }) : super(key: key, child: child);

  final Duration? progress;

  final Duration? total;

  final Duration? buffered;

  final ValueChanged<Duration>? onSeek;

  final ThumbDragStartCallback? onDragStart;

  final ThumbDragUpdateCallback? onDragUpdate;

  final VoidCallback? onDragEnd;

  final bool? isDrawThumb;

  final double barHeight;

  final Color? backgroundBarColor;

  final Color? progressBarColor;

  final Color? bufferedBarColor;

  final ProgressBarShape progressBarShape;

  final double thumbRadius;

  final Color? thumbColor;

  final Color? thumbBlurColor;

  final double thumbScaleRadius;

  @override
  _RenderProgressBar createRenderObject(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    return _RenderProgressBar(
      progress: progress ?? Duration.zero,
      total: total ?? Duration.zero,
      buffered: buffered ?? Duration.zero,
      onSeek: onSeek,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      barHeight: barHeight,
      isDrawThumb: isDrawThumb ?? false,
      backgroundBarColor: backgroundBarColor ?? primaryColor.withOpacity(0.24),
      progressBarColor: progressBarColor ?? primaryColor,
      bufferedBarColor: bufferedBarColor ?? primaryColor.withOpacity(0.24),
      progressBarShape: progressBarShape,
      thumbRadius: thumbRadius,
      thumbColor: thumbColor ?? primaryColor,
      thumbBlurColor:
          thumbBlurColor ?? (thumbColor ?? primaryColor).withAlpha(80),
      thumbScaleRadius: thumbScaleRadius,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderProgressBar renderObject) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    renderObject
      ..progress = progress ?? Duration.zero
      ..total = total ?? Duration.zero
      ..buffered = buffered ?? Duration.zero
      ..onSeek = onSeek
      ..onDragStart = onDragStart
      ..onDragUpdate = onDragUpdate
      ..onDragEnd = onDragEnd
      ..barHeight = barHeight
      ..backgroundBarColor =
          backgroundBarColor ?? primaryColor.withOpacity(0.24)
      ..progressBarColor = progressBarColor ?? primaryColor
      ..bufferedBarColor = bufferedBarColor ?? primaryColor.withOpacity(0.24)
      ..progressBarShape = progressBarShape
      ..thumbRadius = thumbRadius
      ..thumbColor = thumbColor ?? primaryColor
      ..thumbBlurColor =
          thumbBlurColor ?? (thumbColor ?? primaryColor).withAlpha(80);
  }
}

class ThumbDragDetails {
  const ThumbDragDetails({
    this.timeStamp = Duration.zero,
    this.globalPosition = Offset.zero,
  });

  final Duration timeStamp;

  final Offset globalPosition;

  @override
  String toString() => '${objectRuntimeType(this, 'ThumbDragDetails')}('
      'time: $timeStamp, '
      'global: $globalPosition, ';
}

class _RenderProgressBar extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderProgressBar({
    required Duration progress,
    required Duration total,
    required Duration buffered,
    ValueChanged<Duration>? onSeek,
    ThumbDragStartCallback? onDragStart,
    ThumbDragUpdateCallback? onDragUpdate,
    VoidCallback? onDragEnd,
    required bool isDrawThumb,
    required double barHeight,
    required Color backgroundBarColor,
    required Color progressBarColor,
    required Color bufferedBarColor,
    required ProgressBarShape progressBarShape,
    double thumbRadius = 5.0,
    required Color thumbColor,
    required Color thumbBlurColor,
    double thumbScaleRadius = 30.0,
  })  : _progress = progress,
        _total = total,
        _buffered = buffered,
        _onSeek = onSeek,
        _onDragStartUserCallback = onDragStart,
        _onDragUpdateUserCallback = onDragUpdate,
        _onDragEndUserCallback = onDragEnd,
        _isDrawThumb = isDrawThumb,
        _barHeight = barHeight,
        _backgroundBarColor = backgroundBarColor,
        _progressBarColor = progressBarColor,
        _bufferedBarColor = bufferedBarColor,
        _progressBarShape = progressBarShape,
        _thumbRadius = thumbRadius,
        _thumbColor = thumbColor,
        _thumbBlurColor = thumbBlurColor,
        _thumbScaleRadius = thumbScaleRadius {
    _drag = HorizontalDragGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onEnd = _onDragEnd
      ..onCancel = _finishDrag;
    _thumbValue = _percentOfTotal(_progress);
  }

  HorizontalDragGestureRecognizer? _drag;

  late double _thumbValue;

  bool _userIsDraggingThumb = false;

  void _onDragStart(DragStartDetails details) {
    _userIsDraggingThumb = true;
    _updateThumbPosition(details.localPosition);
    onDragStart?.call(ThumbDragDetails(
      timeStamp: _currentThumbDuration(),
      globalPosition: details.globalPosition,
    ));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updateThumbPosition(details.localPosition);
    onDragUpdate?.call(ThumbDragDetails(
      timeStamp: _currentThumbDuration(),
      globalPosition: details.globalPosition,
    ));
  }

  void _onDragEnd(DragEndDetails details) {
    onDragEnd?.call();
    onSeek?.call(_currentThumbDuration());
    _finishDrag();
  }

  void _finishDrag() {
    _userIsDraggingThumb = false;
    markNeedsPaint();
  }

  Duration _currentThumbDuration() {
    final thumbMilliseconds = _thumbValue * total.inMilliseconds;
    return Duration(milliseconds: thumbMilliseconds.round());
  }

  void _updateThumbPosition(Offset localPosition) {
    final dx = localPosition.dx;
    double lengthBefore = 0.0;
    double lengthAfter = 0.0;

    final barCapRadius = _barHeight / 2;
    double barStart = lengthBefore + barCapRadius;
    double barEnd = size.width - lengthAfter - barCapRadius;
    final barWidth = barEnd - barStart;
    final position = (dx - barStart).clamp(0.0, barWidth);
    _thumbValue = (position / barWidth);
    markNeedsPaint();
  }

  Duration get progress => _progress;
  Duration _progress;

  set progress(Duration value) {
    if (_progress == value) {
      return;
    }
    _progress = value;
    if (!_userIsDraggingThumb) {
      _thumbValue = _percentOfTotal(value);
    }
    markNeedsPaint();
  }

  Duration get total => _total;
  Duration _total;

  set total(Duration value) {
    if (_total == value) {
      return;
    }

    _total = value;
    if (!_userIsDraggingThumb) {
      _thumbValue = _percentOfTotal(progress);
    }
    markNeedsPaint();
  }

  Duration get buffered => _buffered;
  Duration _buffered;

  set buffered(Duration value) {
    if (_buffered == value) {
      return;
    }
    _buffered = value;
    markNeedsPaint();
  }

  ValueChanged<Duration>? get onSeek => _onSeek;
  ValueChanged<Duration>? _onSeek;

  set onSeek(ValueChanged<Duration>? value) {
    if (value == _onSeek) {
      return;
    }
    _onSeek = value;
  }

  ThumbDragStartCallback? get onDragStart => _onDragStartUserCallback;
  ThumbDragStartCallback? _onDragStartUserCallback;

  set onDragStart(ThumbDragStartCallback? value) {
    if (value == _onDragStartUserCallback) {
      return;
    }
    _onDragStartUserCallback = value;
  }

  ThumbDragUpdateCallback? get onDragUpdate => _onDragUpdateUserCallback;
  ThumbDragUpdateCallback? _onDragUpdateUserCallback;

  set onDragUpdate(ThumbDragUpdateCallback? value) {
    if (value == _onDragUpdateUserCallback) {
      return;
    }
    _onDragUpdateUserCallback = value;
  }

  VoidCallback? get onDragEnd => _onDragEndUserCallback;
  VoidCallback? _onDragEndUserCallback;

  set onDragEnd(VoidCallback? value) {
    if (value == _onDragEndUserCallback) {
      return;
    }
    _onDragEndUserCallback = value;
  }

  bool get isDrawThumb => _isDrawThumb;
  bool _isDrawThumb;

  set isDrawThumb(bool value) {
    if (_isDrawThumb == value) return;
    _isDrawThumb = value;
    markNeedsLayout();
  }

  double get barHeight => _barHeight;
  double _barHeight;

  set barHeight(double value) {
    if (_barHeight == value) return;
    _barHeight = value;
    markNeedsPaint();
  }

  Color get backgroundBarColor => _backgroundBarColor;
  Color _backgroundBarColor;

  set backgroundBarColor(Color value) {
    if (_backgroundBarColor == value) return;
    _backgroundBarColor = value;
    markNeedsPaint();
  }

  Color get progressBarColor => _progressBarColor;
  Color _progressBarColor;

  set progressBarColor(Color value) {
    if (_progressBarColor == value) return;
    _progressBarColor = value;
    markNeedsPaint();
  }

  Color get bufferedBarColor => _bufferedBarColor;
  Color _bufferedBarColor;

  set bufferedBarColor(Color value) {
    if (_bufferedBarColor == value) return;
    _bufferedBarColor = value;
    markNeedsPaint();
  }

  ProgressBarShape get progressBarShape => _progressBarShape;
  ProgressBarShape _progressBarShape;

  set progressBarShape(ProgressBarShape value) {
    if (_progressBarShape == value) return;
    _progressBarShape = value;
    markNeedsPaint();
  }

  Color get thumbColor => _thumbColor;
  Color _thumbColor;

  set thumbColor(Color value) {
    if (_thumbColor == value) return;
    _thumbColor = value;
    markNeedsPaint();
  }

  double get thumbRadius => _thumbRadius;
  double _thumbRadius;

  set thumbRadius(double value) {
    if (_thumbRadius == value) return;
    _thumbRadius = value;
    markNeedsLayout();
  }

  Color get thumbBlurColor => _thumbBlurColor;
  Color _thumbBlurColor;

  set thumbBlurColor(Color value) {
    if (_thumbBlurColor == value) return;
    _thumbBlurColor = value;
    if (_userIsDraggingThumb) markNeedsPaint();
  }

  double get thumbScaleRadius => _thumbScaleRadius;
  double _thumbScaleRadius;

  set thumbScaleRadius(double value) {
    if (_thumbScaleRadius == value) return;
    _thumbScaleRadius = value;
    markNeedsLayout();
  }

  // The smallest that this widget would ever want to be.
  static const _minDesiredWidth = 100.0;

  @override
  double computeMinIntrinsicWidth(double height) => _minDesiredWidth;

  @override
  double computeMaxIntrinsicWidth(double height) => _minDesiredWidth;

  @override
  double computeMinIntrinsicHeight(double width) => _calDesiredHeight();

  @override
  double computeMaxIntrinsicHeight(double width) => _calDesiredHeight();

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      _drag?.addPointer(event);
    }
  }

  @override
  void performLayout() {
    final child = this.child;

    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      final height = child.size.height + computeDryLayout(constraints).height;
      size = Size(computeDryLayout(constraints).width, height);
    } else {
      size = computeDryLayout(constraints);
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final desiredWidth = constraints.maxWidth;
    final desiredHeight = _calDesiredHeight();
    final desiredSize = Size(desiredWidth, desiredHeight);
    return constraints.constrain(desiredSize);
  }

  double _calDesiredHeight() {
    final child = this.child;
    if (child != null) {
      final barHeight = max(2 * _thumbRadius, _barHeight);
      return barHeight + child.size.height;
    } else {
      return max(2 * _thumbRadius, _barHeight);
    }
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    _drawProgressBarWithoutLabels(canvas, offset.dx);

    _drawGroup(context, canvas, offset);

    canvas.restore();
  }

  void _drawGroup(PaintingContext context, Canvas canvas, Offset offset) {
    // print("MTHAI offset $offset");
    final child = this.child;
    if (child != null) {
      context.paintChild(child, Offset(offset.dx, 40));
    }
  }

  void _drawProgressBarWithoutLabels(Canvas canvas, double dx) {
    final barWidth = size.width;
    final barHeight = 2 * _thumbRadius;
    _drawProgressBar(
        canvas, Offset(dx, size.height - barHeight), Size(barWidth, barHeight));
  }

  void _drawProgressBar(Canvas canvas, Offset offset, Size localSize) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _drawBackgroundBar(canvas, localSize);
    _drawBufferedBar(canvas, localSize);
    _drawCurrentProgressBar(canvas, localSize);
    _drawThumb(canvas, localSize);
    canvas.restore();
  }

  void _drawBackgroundBar(Canvas canvas, Size localSize) {
    _drawBar(
      canvas: canvas,
      availableSize: localSize,
      widthPercent: 1.0,
      color: backgroundBarColor,
    );
  }

  void _drawBufferedBar(Canvas canvas, Size localSize) {
    _drawBar(
      canvas: canvas,
      availableSize: localSize,
      widthPercent: _percentOfTotal(_buffered),
      color: bufferedBarColor,
    );
  }

  void _drawCurrentProgressBar(Canvas canvas, Size localSize) {
    var widthPercent = 0.0;

    if (_userIsDraggingThumb) {
      widthPercent = _thumbValue;
    } else {
      widthPercent = _percentOfTotal(_progress);
    }

    _drawBar(
      canvas: canvas,
      availableSize: localSize,
      widthPercent: widthPercent,
      color: progressBarColor,
    );
  }

  void _drawBar(
      {required Canvas canvas,
      required Size availableSize,
      required double widthPercent,
      required Color color}) {
    final strokeCap = (_progressBarShape == ProgressBarShape.round)
        ? StrokeCap.round
        : StrokeCap.square;
    final backgroundBarPaint = Paint()
      ..color = color
      ..strokeCap = strokeCap
      ..strokeWidth = _barHeight;
    final capRadius = _barHeight / 2;
    final adjustedWidth = availableSize.width - barHeight;
    final dx = widthPercent * adjustedWidth + capRadius;
    final startPoint = Offset(capRadius, availableSize.height / 2);
    var endPoint = Offset(dx, availableSize.height / 2);
    canvas.drawLine(startPoint, endPoint, backgroundBarPaint);
  }

  void _drawThumb(Canvas canvas, Size localSize) {
    final thumbPaint = Paint()..color = thumbColor;
    final barCapRadius = _barHeight / 2;
    final availableWidth = localSize.width - _barHeight;

    // method clamp() => extension function, kiểm tra giá trị truyền vào có nằm trong khoảng cho phép hay k, nếu có return chính nó, ngược lại trả về value start(end)
    var thumbDx = (_thumbValue * availableWidth + barCapRadius)
        .clamp(_thumbRadius, localSize.width - _thumbRadius);

    final center = Offset(thumbDx, localSize.height / 2);
    if (_userIsDraggingThumb) {
      final thumbGlowPaint = Paint()..color = thumbBlurColor;
      canvas.drawCircle(center, thumbScaleRadius, thumbGlowPaint);
    }
    canvas.drawCircle(center, thumbRadius, thumbPaint);
  }

  double _percentOfTotal(Duration duration) {
    if (total.inMilliseconds == 0) {
      return 0.0;
    }
    return duration.inMilliseconds / total.inMilliseconds;
  }
}
