import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'custom/player_indicator_shape.dart';
import 'custom/player_path_painter.dart';

class AdvancedOverlayWidget extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback onClickedFullScreen;

  final double sliderValue;
  final String position;
  final bool validPosition;
  final PlayerIndicatorShape indicatorShape;

  final ui.Image? image;

  final ValueChanged<double> onPositionChanged;
  final ValueChanged<Offset> onOffsetChanged;
  final ValueChanged<bool> onDragging;

  static const allSpeeds = <double>[0.25, 0.5, 1, 1.5, 2, 3, 5, 10];

  const AdvancedOverlayWidget({
    Key? key,
    required this.controller,
    required this.sliderValue,
    required this.position,
    required this.validPosition,
    required this.indicatorShape,
    required this.image,
    required this.onPositionChanged,
    required this.onOffsetChanged,
    required this.onDragging,
    required this.onClickedFullScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            controller.value.isPlaying ? controller.pause() : controller.play(),
        child: Stack(
          children: <Widget>[
            buildPlay(),
            buildSpeed(),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Expanded(child: buildIndicator(context)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onClickedFullScreen,
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                )),
          ],
        ),
      );

  Widget buildIndicator(BuildContext context) => SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackShape: const RectangularSliderTrackShape(),
          activeTrackColor: Colors.blue[700],
          inactiveTrackColor: Colors.blue[100],
          trackHeight: 4.0,
          thumbShape: SliderComponentShape.noOverlay,
          thumbColor: Colors.blueAccent,
          overlayColor: Colors.blueAccent,
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 6.0),
          tickMarkShape: const RoundSliderTickMarkShape(),
          activeTickMarkColor: Colors.blue[700],
          inactiveTickMarkColor: Colors.blue[100],
          valueIndicatorTextStyle: const TextStyle(
            color: Colors.white,
          ),
        ),
        child: PlayerSlider(
          value: sliderValue,
          min: 0.0,
          max: (!validPosition)
              ? 1.0
              : controller.value.duration.inSeconds.toDouble(),
          label: position,
          divisions: controller.value.duration.inSeconds,
          onChanged: validPosition ? onPositionChanged : null,
          onChangeStart: (_) {
            controller.pause();
            onDragging(true);
          },
          onChangeEnd: (_) {
            controller.play();
            onDragging(false);
          },
          onOffsetChange: onOffsetChanged,
          image: image,
          indicatorShape: indicatorShape,
        ),
      );

  Widget buildSpeed() => Align(
        alignment: Alignment.topRight,
        child: PopupMenuButton<double>(
          initialValue: controller.value.playbackSpeed,
          tooltip: 'Playback speed',
          onSelected: controller.setPlaybackSpeed,
          itemBuilder: (context) => allSpeeds
              .map<PopupMenuEntry<double>>((speed) => PopupMenuItem(
                    value: speed,
                    child: Text('${speed}x'),
                  ))
              .toList(),
          child: Container(
            color: Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text('${controller.value.playbackSpeed}x'),
          ),
        ),
      );

  Widget buildPlay() {
    return controller.value.isPlaying
        ? Container()
        : Container(
            color: Colors.black26,
            child: const Center(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 70,
              ),
            ),
          );
  }
}
