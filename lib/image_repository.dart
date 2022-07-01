import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bitmap/bitmap.dart';
import 'package:flutter/cupertino.dart';

class PreviewFrame {
  int posMs;
  Uint8List source;

  PreviewFrame(this.posMs, this.source);
}

extension FutureExtension<T> on Future<T> {
  bool isCompleted() {
    final completer = Completer<T>();
    then(completer.complete).catchError(completer.completeError);
    return completer.isCompleted;
  }
}

class RenderBitmap {
  static final RenderBitmap _singleton = RenderBitmap._internal();

  factory RenderBitmap() {
    return _singleton;
  }

  RenderBitmap._internal();

  Future<List<Uint8List>> getImageSourceFormUrl(
      String url, int countChildImageRow, int countChildImageColumn) async {
    if (countChildImageColumn == 0 || countChildImageRow == 0) {
      return [];
    }

    final bitmap = await Bitmap.fromProvider(NetworkImage(url));
    final widthImage = bitmap.width;
    final heightImage = bitmap.height;

    final List<Uint8List> images = [];

    final widthImageCrop = widthImage ~/ countChildImageRow.toInt();
    final heightImageCrop = heightImage ~/ countChildImageColumn;

    var xPos = 0;
    var yPos = 0;

    for (int i = 0; i < countChildImageColumn; i++) {
      for (int j = 0; j < countChildImageRow; j++) {
        var newBitmap = bitmap.applyBatch([
          BitmapCrop.fromLTWH(
              left: xPos,
              top: yPos,
              width: widthImageCrop,
              height: heightImageCrop)
        ]);
        images.add(newBitmap.buildHeaded());
        xPos += widthImageCrop;
      }
      xPos = 0;
      yPos += heightImageCrop;
    }

    return images;
  }

  Future<List<ui.Image>> getUiImageFormUrl(
      String url, int countChildImageRow, int countChildImageColumn) async {
    if (countChildImageColumn == 0 || countChildImageRow == 0) {
      return [];
    }

    final bitmap = await Bitmap.fromProvider(NetworkImage(url));
    final widthImage = bitmap.width;
    final heightImage = bitmap.height;

    final List<ui.Image> images = [];

    final widthImageCrop = widthImage ~/ countChildImageRow.toInt();
    final heightImageCrop = heightImage ~/ countChildImageColumn;

    var xPos = 0;
    var yPos = 0;

    for (int i = 0; i < countChildImageColumn; i++) {
      for (int j = 0; j < countChildImageRow; j++) {
        var newBitmap = bitmap.applyBatch([
          BitmapCrop.fromLTWH(
              left: xPos,
              top: yPos,
              width: widthImageCrop,
              height: heightImageCrop)
        ]);
        var uiImage = await newBitmap.buildImage();

        images.add(uiImage);
        xPos += widthImageCrop;
      }
      xPos = 0;
      yPos += heightImageCrop;
    }

    return images;
  }
}
