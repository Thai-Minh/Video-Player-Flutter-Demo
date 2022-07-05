import 'dart:async';

import 'package:flutter/material.dart';

class PreviewLoader {
  static Future<Image> loadImage(int positionInMs) async {
    return Image.asset("dog.png");
  }
}