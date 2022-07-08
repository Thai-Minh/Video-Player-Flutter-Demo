import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const double _previewPaddingHorizontal = 10;

class ProgressPreview extends SingleChildRenderObjectWidget {
  final double progress;

  const ProgressPreview({
    Key? key,
    required Widget child,
    required this.progress,
  }) : super(key: key, child: child);

  @override
  RenderPreviewBox createRenderObject(BuildContext context) {
    return RenderPreviewBox(progress: progress);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderPreviewBox renderObject) {
    renderObject.progress = progress;
  }
}

class RenderPreviewBox extends RenderShiftedBox {
  double _progress;

  double get progress => _progress;

  set progress(double value) {
    if (_progress == value) return;
    _progress = value;
    markNeedsLayout();
  }

  RenderPreviewBox({RenderBox? child, required double progress})
      : _progress = progress,
        super(child);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final bool shrinkWrapWidth = constraints.maxWidth == double.infinity;
    final bool shrinkWrapHeight = constraints.maxHeight == double.infinity;

    final child = this.child;

    if (child != null) {
      final Size childSize = child.getDryLayout(constraints.loosen());
      return constraints.constrain(Size(
        shrinkWrapWidth ? childSize.width : double.infinity,
        shrinkWrapHeight ? childSize.height : double.infinity,
      ));
    }
    return constraints.constrain(Size(
      shrinkWrapWidth ? 0.0 : double.infinity,
      shrinkWrapHeight ? 0.0 : double.infinity,
    ));
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final bool shrinkWrapWidth = constraints.maxWidth == double.infinity;
    final bool shrinkWrapHeight = constraints.maxHeight == double.infinity;
    final child = this.child;

    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(Size(
        shrinkWrapWidth ? child.size.width : double.infinity,
        shrinkWrapHeight ? child.size.height : double.infinity,
      ));
      _offsetChild();
    } else {
      size = constraints.constrain(Size(
        shrinkWrapWidth ? 0.0 : double.infinity,
        shrinkWrapHeight ? 0.0 : double.infinity,
      ));
    }
  }

  void _offsetChild() {
    final child = this.child;
    if (child != null) {
      double dx = (size.width * progress);

      if (dx - child.size.width / 2 < 0) {
        dx = _previewPaddingHorizontal;
      } else if (dx + child.size.width / 2 > size.width) {
        dx = size.width - child.size.width - _previewPaddingHorizontal;
      } else {
        dx = dx - child.size.width / 2;
      }

      final BoxParentData childParentData = child.parentData as BoxParentData;
      childParentData.offset = Offset(dx, 10.0);
    }
  }
}
