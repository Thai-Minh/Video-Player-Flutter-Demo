import 'package:flutter/material.dart';
import 'package:helloworld/preview_loader.dart';
import 'package:video_player/video_player.dart' as player;

import 'custom/player_indicator_shape.dart';

enum ControllerAction { next, previous, play }

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({Key? key}) : super(key: key);

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late player.VideoPlayerController _controller;

  int get duration => _controller.value.duration.inMilliseconds;

  int get position => _controller.value.position.inMilliseconds;

  double offsetX = 0.0;
  bool isShowPreview = false;

  @override
  void initState() {
    super.initState();

    _controller = player.VideoPlayerController.network(
      "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd",
      videoPlayerOptions: player.VideoPlayerOptions(
        allowBackgroundPlayback: true,
      ),
    )..initialize().then((value) => setState(() => {}));

    _controller.setLooping(true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _controller.value.isInitialized
            ? _Player(controller: _controller)
            : const Center(child: CircularProgressIndicator()),
        _CenterController(
          isPlaying: _controller.value.isPlaying,
          onPositionChanged: onControllerClicked,
        ),
        _Overlay(
          isShow: isShowPreview,
          offsetX: offsetX,
          position: position,
        ),
      ],
    );
  }

  void onControllerClicked(ControllerAction action) {
    switch (action) {
      case ControllerAction.play:
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
        break;
      case ControllerAction.next:
        if (position < _controller.value.duration.inMilliseconds) {
          _controller.seekTo(Duration(milliseconds: position + 5000));
        } else {
          _controller.seekTo(_controller.value.duration);
        }
        break;
      case ControllerAction.previous:
        if (position > 5) {
          _controller.seekTo(Duration(milliseconds: position - 5000));
        } else {
          _controller.seekTo(const Duration(seconds: 0));
        }
        break;
    }
  }
}

class _BottomController extends StatelessWidget {
  final player.VideoPlayerController controller;
  final VoidCallback onClickedFullScreen;

  const _BottomController({Key? key, required this.controller, required this.onClickedFullScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
        ),);
  }

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

            },
            // image: images.isNotEmpty ? images[0] : null,
            image: null,
          )),
    );
  }
}


class _CenterController extends StatelessWidget {
  final bool isPlaying;
  final ValueChanged<ControllerAction> onPositionChanged;

  const _CenterController(
      {Key? key, required this.onPositionChanged, required this.isPlaying})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isPlaying ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black26,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildPlayerIcon(ControllerAction.previous, Icons.skip_previous,
                    30, onPositionChanged),
                const SizedBox(width: 30),
                buildPlayerIcon(
                    ControllerAction.play,
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    60,
                    onPositionChanged),
                const SizedBox(width: 30),
                buildPlayerIcon(ControllerAction.next, Icons.skip_next, 30,
                    onPositionChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPlayerIcon(ControllerAction action, IconData icon, double size,
      ValueChanged<ControllerAction> onPositionChanged) {
    return InkWell(
      onTap: () {
        onPositionChanged(action);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Icon(
          icon,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }
}

class _Player extends StatelessWidget {
  final player.VideoPlayerController controller;

  const _Player({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: player.VideoPlayer(controller),
    );
  }
}

class _Overlay extends StatelessWidget {
  final bool isShow;
  final double offsetX;
  final int position;

  const _Overlay(
      {Key? key,
      required this.isShow,
      required this.offsetX,
      required this.position})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Image>(
        future: PreviewLoader.loadImage(position),
        builder: (context, snapshot) {
          final image = snapshot.data;

          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Expanded(
              child: Stack(
                key: key,
                alignment: AlignmentDirectional.center,
                children: [
                  Positioned(
                    left: offsetX,
                    child: Container(
                      color: Colors.grey,
                      width: 160.0,
                      height: 90.0,
                      child: image,
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }
}
