import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

typedef void OnWidgetSizeChange(Size size);
typedef void OnPageChanged(List<Offset> vertices);

class DecodeParam {
  final ByteData byteData;
  final SendPort sendPort;

  DecodeParam(this.byteData, this.sendPort);
}

void decodeImageFromBytes(DecodeParam param) {}

Future<ui.Image?> loadUiImage(String imagePath) async {
  Uri imgUri = Uri.parse(imagePath);
  File imageFile = File.fromUri(imgUri);
  Uint8List data = await imageFile.readAsBytes();
  final codec = await ui.instantiateImageCodec(data);
  final frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({Key? key, required this.onChange, required this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  var widgetKey = GlobalKey();
  var _widgetSize = Size(-1, -1);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      var currSize = widgetKey.currentContext!.size!;
      if (currSize.width != _widgetSize.width ||
          currSize.height != _widgetSize.height) {
        _widgetSize = currSize;
        widget.onChange(currSize);
      }
    });

    return Container(
      key: widgetKey,
      child: widget.child,
    );
  }
}

class CSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  CSButton({Key? key, required this.text, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.green, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: onPressed,
          child: Text(text, style: TextStyle(fontSize: 18))),
    );
  }
}

class CSRateResult {
  CSRateResult(this.isAppGood, this.isAppMedium, this.isAppBad, this.isCSGood,
      this.isCSMedium, this.isCSBad);

  final bool isAppGood, isAppMedium, isAppBad;
  final bool isCSGood, isCSMedium, isCSBad;
}

typedef OnCSRateChangedListener = Function(CSRateResult result);

class CSRating extends StatefulWidget {
  final OnCSRateChangedListener listener;
  bool isAppGood = true;
  bool isAppBad = false;
  bool isAppMedium = false;

  bool isCSGood = true;
  bool isCSBad = false;
  bool isCSMedium = false;

  CSRating(
      {required this.listener,
      this.isAppGood = true,
      this.isAppMedium = false,
      this.isAppBad = false,
      this.isCSGood = true,
      this.isCSMedium = false,
      this.isCSBad = false});

  @override
  _CSRatingState createState() => _CSRatingState();
}

class _CSRatingState extends State<CSRating> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 72.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_appRateRow(), _csRateRow()],
        ));
  }

  Widget _appRateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 70.0,
          height: 36.0,
          child: Center(
            child: Text('App'),
          ),
        ),
        _CSCheckBox(widget.isAppGood, 'Good', (bool value) {
          _onAppCheckBoxChanged(0, value);
        }),
        _CSCheckBox(widget.isAppMedium, 'Medium', (bool value) {
          _onAppCheckBoxChanged(1, value);
        }),
        _CSCheckBox(widget.isAppBad, 'Bad', (bool value) {
          _onAppCheckBoxChanged(2, value);
        })
      ],
    );
  }

  Widget _csRateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 70.0,
          height: 36.0,
          child: Center(
            child: Text('CS'),
          ),
        ),
        _CSCheckBox(widget.isCSGood, 'Good', (bool value) {
          _onCSCheckBoxChanged(0, value);
        }),
        _CSCheckBox(widget.isCSMedium, 'Medium', (bool value) {
          _onCSCheckBoxChanged(1, value);
        }),
        _CSCheckBox(widget.isCSBad, 'Bad', (bool value) {
          _onCSCheckBoxChanged(2, value);
        })
      ],
    );
  }

  void _onAppCheckBoxChanged(int index, bool value) {
    if (!value) return;
    setState(() {
      widget.isAppGood = false;
      widget.isAppMedium = false;
      widget.isAppBad = false;
      switch (index) {
        case 0:
          widget.isAppGood = value;
          break;
        case 1:
          widget.isAppMedium = value;
          break;
        case 2:
          widget.isAppBad = value;
          break;
      }
      widget.listener(CSRateResult(widget.isAppGood, widget.isAppMedium,
          widget.isAppBad, widget.isCSGood, widget.isCSMedium, widget.isCSBad));
    });
  }

  void _onCSCheckBoxChanged(int index, bool value) {
    if (!value) return;
    setState(() {
      widget.isCSGood = false;
      widget.isCSMedium = false;
      widget.isCSBad = false;
      switch (index) {
        case 0:
          widget.isCSGood = value;
          break;
        case 1:
          widget.isCSMedium = value;
          break;
        case 2:
          widget.isCSBad = value;
          break;
      }
      widget.listener(CSRateResult(widget.isAppGood, widget.isAppMedium,
          widget.isAppBad, widget.isCSGood, widget.isCSMedium, widget.isCSBad));
    });
  }
}

class _CSCheckBox extends StatelessWidget {
  const _CSCheckBox(this.isChecked, this.title, this.onChanged);

  final bool isChecked;
  final String title;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused
      };

      if (states.any(interactiveStates.contains)) {
        return Colors.red;
      }
      return Colors.blue;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
            height: 24.0,
            width: 24.0,
            child: Checkbox(
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith(getColor),
                value: isChecked,
                onChanged: (bool? value) {
                  onChanged(value!);
                })),
        const SizedBox(width: 4.0),
        Text(title)
      ],
    );
  }
}

// TODO example
class CSImageCropping extends StatefulWidget {
  final String imagePath;
  List<Offset> vertices = <Offset>[];
  final OnPageChanged pageChangedListener;

  CSImageCropping(
      {Key? key,
      required this.imagePath,
      required this.vertices,
      required this.pageChangedListener})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CSImageCroppingState();
}

class _MutableRect {
  var left = 0.0;
  var top = 0.0;
  var right = 0.0;
  var bottom = 0.0;

  double get width => right - left;

  double get height => bottom - top;

  Rect toRect() {
    return Offset(left, top) & Size(right - left, bottom - top);
  }
}

class _MagnifierInfo {
  final double magnifierSize = 120;
  final double borderWidth = 3.0;
  final double crossStrokeWidth = 2.0;
  final double crossLen = 15.0;
  Rect rectOnCanvas = Offset.zero & Size.zero;
  Rect srcRect = Offset.zero & Size.zero;
  Rect dstRect = Offset.zero & Size.zero;
  Path clipRegion = Path();
  bool isVisible = false;

  void fill(Offset anchor, Size canvasSize, Rect imgRect, Size imgSize) {
    _MutableRect roi = _MutableRect();
    _MutableRect dstMagnifierRect = _MutableRect();
    _MutableRect srcMagnifierRect = _MutableRect();
    _MutableRect magnifierRect = _MutableRect();

    magnifierRect.left = 0.0;
    magnifierRect.top = 0.0;
    magnifierRect.right = magnifierRect.left + magnifierSize;
    magnifierRect.bottom = magnifierRect.top + magnifierSize;
    if (anchor.dx < magnifierRect.right && anchor.dy < magnifierRect.bottom) {
      magnifierRect.left = canvasSize.width - magnifierSize;
      magnifierRect.top = 0.0;
      magnifierRect.right = canvasSize.width;
      magnifierRect.bottom = magnifierRect.top + magnifierSize;
    }
    rectOnCanvas = magnifierRect.toRect();

    clipRegion.reset();
    clipRegion.addArc(rectOnCanvas, 0.0, 360.0);

    dstMagnifierRect.left = rectOnCanvas.left;
    dstMagnifierRect.top = rectOnCanvas.top;
    dstMagnifierRect.right = rectOnCanvas.right;
    dstMagnifierRect.bottom = rectOnCanvas.bottom;

    roi.left = (anchor.dx - imgRect.left - magnifierSize / 2);
    roi.top = (anchor.dy - imgRect.top - magnifierSize / 2);
    roi.right = (roi.left + magnifierSize);
    roi.bottom = (roi.top + magnifierSize);

    if (roi.left < 0) {
      dstMagnifierRect.left -= roi.left;
      roi.left = 0;
    }

    if (roi.left + roi.width > imgRect.width) {
      dstMagnifierRect.right -= (roi.left + roi.width - imgRect.width);
      roi.right = imgRect.right - imgRect.left;
    }

    if (roi.top < 0) {
      dstMagnifierRect.top -= roi.top;
      roi.top = 0;
    }

    if (roi.top + roi.height > imgRect.height) {
      dstMagnifierRect.bottom -= (roi.top + roi.height - imgRect.height);
      roi.bottom = (imgRect.bottom - imgRect.top);
    }

    var scale = imgSize.width / imgRect.width;
    srcMagnifierRect.left = roi.left * scale;
    srcMagnifierRect.top = roi.top * scale;
    srcMagnifierRect.right = roi.right * scale;
    srcMagnifierRect.bottom = roi.bottom * scale;

    srcRect = srcMagnifierRect.toRect();
    dstRect = dstMagnifierRect.toRect();
  }
}

class _CSImageCroppingState extends State<CSImageCropping> {
  List<Offset> anchors = <Offset>[];
  final Color dotColor = Colors.greenAccent;
  final Color lineColor = Colors.lightGreenAccent;
  final double lineStrokeWidth = 1.5;
  final double dotRadius = 10.0;
  final double _clickedDotRadius = 15.0;
  Size _canvasSize = Size(0, 0);
  Size _imgSize = Size(0, 0);
  int _selectedDotIndex = -1;
  ui.Image? _image = null;
  Rect _imageRect = Offset.zero & Size.zero;
  var _lastOffset = Offset.zero;
  _MagnifierInfo _magnifierInfo = _MagnifierInfo();

  _CSImageCroppingState();

  @override
  void initState() {
    super.initState();
    loadUiImage(widget.imagePath).then((value) {
      _image = value;
      _computeImageRect();
    });
  }

  void _onSizeChanged(Size size) {
    _canvasSize = size;
    _computeImageRect();
  }

  void _computeImageRect() {
    var image = _image;
    if (image == null || _canvasSize.width == 0 || _canvasSize.height == 0)
      return;
    _imgSize = Size(image.width.toDouble(), image.height.toDouble());

    var canvasAspect = _canvasSize.width / _canvasSize.height;
    var imgAspect = image.width / image.height;
    var scale = canvasAspect > imgAspect
        ? (_canvasSize.height / image.height)
        : (_canvasSize.width / image.width);

    var left = ((_canvasSize.width - image.width * scale) / 2);
    var top = ((_canvasSize.height - image.height * scale) / 2);
    var right = left + (image.width * scale);
    var bottom = top + (image.height * scale);
    var prevImageRect = _imageRect;
    _imageRect = Offset(left, top) & Size(right - left, bottom - top);
    if (prevImageRect.width == 0 && prevImageRect.width == 0) {
      initAnchors(scale);
    } else {
      _scaleAnchors(prevImageRect, _imageRect);
    }
    updateState();
  }

  void initAnchors(double scale) {
    anchors.clear();
    if (widget.vertices.isEmpty) return;

    widget.vertices.forEach((element) {
      anchors.add(element
          .scale(scale, scale)
          .translate(_imageRect.left, _imageRect.top));
    });
  }

  void _scaleAnchors(Rect oldBound, Rect newBound) {
    if (oldBound.width == 0 || oldBound.height == 0) return;

    var scaleX = newBound.width / oldBound.width;
    var scaleY = newBound.height / oldBound.height;
    List<Offset> scaledAnchors = <Offset>[];
    anchors.forEach((element) {
      scaledAnchors.add(element.scale(scaleX, scaleY));
    });
    anchors = scaledAnchors;
  }

  void updateState() {
    setState(() {
      if (anchors.length == 4) {
        Offset? selectedAnchor =
            _selectedDotIndex != -1 ? anchors[_selectedDotIndex] : null;
        anchors = _orderAnchors(anchors);
        if (selectedAnchor != null)
          _selectedDotIndex = anchors.indexOf(selectedAnchor);

        List<Offset> scaledAnchors = <Offset>[];
        double scale = _imgSize.width / _imageRect.width;
        anchors.forEach((element) {
          scaledAnchors.add(element
              .translate(-_imageRect.left, -_imageRect.top)
              .scale(scale, scale));
        });
        widget.pageChangedListener(scaledAnchors);
      }
    });
  }

  List<Offset> _orderAnchors(List<Offset> anchors) {
    assert(anchors.length == 4);
    // left most
    anchors.sort((obj1, obj2) => obj1.dx.compareTo(obj2.dx));
    Offset tl = anchors[0].dy < anchors[1].dy ? anchors[0] : anchors[1];
    Offset bl = anchors[0] != tl ? anchors[0] : anchors[1];
    var coeffs = _findLineEquation(tl, anchors[2]);
    var c1 = coeffs[0] * bl.dx + coeffs[1] * bl.dy > coeffs[2] ? 1 : -1;
    var c2 = coeffs[0] * anchors[3].dx + coeffs[1] * anchors[3].dy > coeffs[2]
        ? 1
        : -1;
    Offset tr = c1 * c2 > 0 ? anchors[2] : anchors[3];
    Offset br = anchors[2] != tr ? anchors[2] : anchors[3];
    return <Offset>[tl, tr, br, bl];
  }

  // ax + by = c
  List<double> _findLineEquation(Offset p1, Offset p2) {
    var a = p2.dy - p1.dy;
    var b = -(p2.dx - p1.dx);
    var c = a * p1.dx + b * p1.dy;
    return <double>[a, b, c];
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerRelease,
      onPointerCancel: _onPointerRelease,
      child: MeasureSize(
        onChange: _onSizeChanged,
        child: CustomPaint(
            painter: _CoppingPainter(_image, _imageRect, _magnifierInfo,
                anchors, dotColor, dotRadius, lineColor, lineStrokeWidth),
            size: Size.infinite),
      ),
    );
  }

  void checkClickedOnAnchor(double x, double y) {
    for (int i = 0; i < anchors.length; ++i) {
      var element = anchors[i];
      if (element.dx - _clickedDotRadius < x &&
          x < element.dx + _clickedDotRadius &&
          element.dy - _clickedDotRadius < y &&
          y < element.dy + _clickedDotRadius) {
        _selectedDotIndex = i;
      }
    }
  }

  void _onPointerDown(PointerEvent details) {
    checkClickedOnAnchor(details.localPosition.dx, details.localPosition.dy);
    _lastOffset = Offset(details.localPosition.dx, details.localPosition.dy);
    if (_selectedDotIndex != -1) {
      var img = _image;
      if (img != null)
        _magnifierInfo.fill(anchors[_selectedDotIndex], _canvasSize, _imageRect,
            Size(img.width * 1.0, img.height * 1.0));
    }
  }

  void _onPointerMove(PointerEvent details) {
    var selectedDotIndex = _selectedDotIndex;
    if (selectedDotIndex == -1) return;
    _magnifierInfo.isVisible = true;
    var selectDot = anchors[selectedDotIndex];
    var deltaX = details.localPosition.dx - _lastOffset.dx;
    var deltaY = details.localPosition.dy - _lastOffset.dy;
    _lastOffset = details.localPosition;

    List<double> coord =
        checkAnchor(selectDot.dx + deltaX, selectDot.dy + deltaY);
    anchors[selectedDotIndex] = Offset(coord[0], coord[1]);
    var img = _image;
    if (img != null)
      _magnifierInfo.fill(anchors[_selectedDotIndex], _canvasSize, _imageRect,
          Size(img.width * 1.0, img.height * 1.0));
    updateState();
  }

  List<double> checkAnchor(double x, double y) {
    if (x < _imageRect.left) {
      x = _imageRect.left;
    }
    if (x > _imageRect.right) {
      x = _imageRect.right;
    }

    if (y < _imageRect.top) {
      y = _imageRect.top;
    }
    if (y > _imageRect.bottom) {
      y = _imageRect.bottom;
    }
    return <double>[x, y];
  }

  void _onPointerRelease(PointerEvent details) {
    _selectedDotIndex = -1;
    if (_magnifierInfo.isVisible) {
      _magnifierInfo.isVisible = false;
      updateState();
    }
  }
}

class _CoppingPainter extends CustomPainter {
  final List<Offset> anchors;
  final Rect imageRect;
  final ui.Image? image;
  final Paint dotPaint = Paint();
  final Paint linePaint = Paint();
  final Paint bgPaint = Paint();
  final Paint fogPaint = Paint();
  final Paint magnifierPaint = Paint();
  final double dotRadius;
  final Path fogPath = Path();
  final _MagnifierInfo magnifierInfo;

  _CoppingPainter(this.image, this.imageRect, this.magnifierInfo, this.anchors,
      Color dotColor, this.dotRadius, Color lineColor, double lineStrokeWidth) {
    dotPaint
      ..color = dotColor
      ..style = PaintingStyle.fill;

    linePaint
      ..color = lineColor
      ..strokeWidth = lineStrokeWidth
      ..style = PaintingStyle.stroke;

    bgPaint
      ..color = Colors.black26
      ..style = PaintingStyle.fill;

    fogPaint..color = Colors.white.withAlpha(102);
  }

  void _drawMagnifier(Canvas canvas, Size size) {
    var img = image;
    if (img == null) return;

    canvas.save();
    canvas.clipPath(magnifierInfo.clipRegion);
    magnifierPaint
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, magnifierPaint);
    canvas.drawImageRect(
        img, magnifierInfo.srcRect, magnifierInfo.dstRect, magnifierPaint);

    magnifierPaint
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = magnifierInfo.borderWidth;

    canvas.drawCircle(magnifierInfo.rectOnCanvas.center,
        magnifierInfo.magnifierSize / 2, magnifierPaint);
    magnifierPaint
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = magnifierInfo.crossStrokeWidth;

    Offset center = magnifierInfo.rectOnCanvas.center;

    canvas.drawLine(
        Offset(center.dx - magnifierInfo.crossLen / 2, center.dy),
        Offset(center.dx + magnifierInfo.crossLen / 2, center.dy),
        magnifierPaint);

    canvas.drawLine(
        Offset(center.dx, center.dy - magnifierInfo.crossLen / 2),
        Offset(center.dx, center.dy + magnifierInfo.crossLen / 2),
        magnifierPaint);

    canvas.restore();
  }

  void _drawAnchors(Canvas canvas, Size size) {
    anchors.forEach((element) {
      canvas.drawCircle(element, dotRadius, dotPaint);
    });
  }

  void _drawFog(Canvas canvas, Size size) {
    if (anchors.isEmpty) return;
    fogPath.reset();
    fogPath.moveTo(anchors[0].dx, anchors[0].dy);
    for (int i = 1; i < anchors.length; ++i) {
      fogPath.lineTo(anchors[i].dx, anchors[i].dy);
    }
    canvas.save();
    canvas.clipPath(fogPath);
    canvas.drawRect(Offset.zero & size, fogPaint);
    canvas.restore();
  }

  void _drawLinesBetweenDots(Canvas canvas, Size size) {
    for (int i = 0; i < anchors.length; ++i) {
      if (i == 0) {
        linePaint.color = Colors.red;
      } else {
        linePaint.color = Colors.lightGreenAccent;
      }
      canvas.drawLine(anchors[i], anchors[(i + 1) % anchors.length], linePaint);
    }
  }

  void _drawImages(Canvas canvas, Size size) {
    var img = image;
    if (img == null) return;
    if (imageRect.width == 0 || imageRect.height == 0) return;

    canvas.drawImageRect(
        img,
        Offset.zero & Size(img.width * 1.0, img.height * 1.0),
        imageRect,
        Paint());
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (anchors.isEmpty) return;
    _drawImages(canvas, size);
    _drawFog(canvas, size);
    _drawLinesBetweenDots(canvas, size);
    _drawAnchors(canvas, size);
    if (magnifierInfo.isVisible) _drawMagnifier(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _CoppingPainter other) =>
      other.anchors != anchors || other.imageRect != imageRect;
}
