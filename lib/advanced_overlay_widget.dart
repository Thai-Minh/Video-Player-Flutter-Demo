import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'custom/player_indicator_shape.dart';
import 'custom/player_path_painter.dart';

class AdvancedOverlayWidget extends StatelessWidget {
  final VideoPlayerController controller;

  final double sliderValue;
  final String position;
  final bool validPosition;

  final PlayerIndicatorShape indicatorShape;

  final List<ui.Image> images;

  final ValueChanged<double> onPositionChanged;
  final OffsetChanged offsetChanged;
  final VoidCallback onClickedFullScreen;

  static const allSpeeds = <double>[0.25, 0.5, 1, 1.5, 2, 3, 5, 10];

  const AdvancedOverlayWidget({
    Key? key,
    required this.controller,
    required this.sliderValue,
    required this.position,
    required this.validPosition,
    required this.indicatorShape,
    required this.images,
    required this.onPositionChanged,
    required this.offsetChanged,
    required this.onClickedFullScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          buildPlay(),
          buildSpeed(),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(child: buildIndicator(context)),
                  const SizedBox(width: 8),
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
      );

  Widget buildIndicator(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackShape: const RectangularSliderTrackShape(),
        activeTrackColor: Colors.blue[700],
        inactiveTrackColor: Colors.blue[100],
        trackHeight: 4.0,
        thumbShape: SliderComponentShape.noOverlay,
        thumbColor: Colors.blueAccent,
        overlayColor: Colors.blueAccent,
        // overlayShape: const RoundSliderOverlayShape(overlayRadius: 6.0),
        overlayShape: SliderComponentShape.noOverlay,
        tickMarkShape: const RoundSliderTickMarkShape(),
        activeTickMarkColor: Colors.blue[700],
        inactiveTickMarkColor: Colors.blue[100],
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      child: SizedBox(
          height: 40,
          child: PlayerSlider(
            value: sliderValue,
            min: 0.0,
            max: (!validPosition)
                ? 1.0
                : controller.value.duration.inSeconds.toDouble(),
            // label: position,
            divisions: controller.value.duration.inSeconds,
            onChanged: validPosition ? onPositionChanged : null,
            onChangeStart: (_) {
              controller.pause();
            },
            onChangeEnd: (_) {
              controller.play();
            },
            onOffsetChanged: (center, isDragging) {
              offsetChanged(center, isDragging);
            },
            // image: images.isNotEmpty ? images[0] : null,
            image: null,
            indicatorShape: indicatorShape,
          )),
    );
  }

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
    return AnimatedOpacity(
        opacity: !controller.value.isPlaying ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        // The green box must be a child of the AnimatedOpacity widget.
        child: Container(
          color: Colors.black26,
          child: Center(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                buildPlayerIcon(PlayAction.previous, Icons.skip_previous, 30),
                const SizedBox(width: 40),
                buildPlayerIcon(PlayAction.play, Icons.play_arrow, 70),
                const SizedBox(width: 40),
                buildPlayerIcon(PlayAction.next, Icons.skip_next, 30),
              ])),
        ));
  }

  Widget buildPlayerIcon(PlayAction action, IconData icon, double size) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Duration currentPosition = controller.value.position;

          switch (action) {
            case PlayAction.play:
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              break;
            case PlayAction.next:
              if (currentPosition.inSeconds <
                  controller.value.duration.inSeconds) {
                controller.seekTo(currentPosition + const Duration(seconds: 5));
              } else {
                controller.seekTo(controller.value.duration);
              }
              break;
            case PlayAction.previous:
              if (currentPosition.inSeconds > 5) {
                controller.seekTo(currentPosition - const Duration(seconds: 5));
              } else {
                controller.seekTo(const Duration(seconds: 0));
              }
              break;
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Icon(
            icon,
            color: Colors.white,
            size: size,
          ),
        ));
  }
}

enum PlayAction { next, previous, play }
