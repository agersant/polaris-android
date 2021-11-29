import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/transformers.dart';

final getIt = GetIt.instance;

class StreamingIndicator extends StatefulWidget {
  const StreamingIndicator({Key? key}) : super(key: key);

  @override
  State<StreamingIndicator> createState() => _StreamingIndicatorState();
}

class _StreamingIndicatorState extends State<StreamingIndicator> with TickerProviderStateMixin {
  final audioPlayer = getIt<AudioPlayer>();
  late StreamSubscription _stateSubscription;
  late final AnimationController _controller = AnimationController(vsync: this, value: 0);
  late Stream<bool> bufferingStream;
  bool visible = false;

  @override
  void initState() {
    super.initState();

    final bufferingStream = getIt<AudioPlayer>()
        .playerStateStream
        .debounceTime(const Duration(milliseconds: 100))
        .map((state) => _isBuffering(state));
    _stateSubscription = bufferingStream.listen((buffering) {
      _updateVisibility(buffering);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stateSubscription.cancel();
    _controller.dispose();
  }

  bool _isBuffering(PlayerState playerState) {
    return playerState.processingState == ProcessingState.loading ||
        playerState.processingState == ProcessingState.buffering;
  }

  void _updateVisibility(bool buffering) {
    if (buffering == visible) {
      return;
    }
    final double scaleFactor = buffering ? 1 : 0;
    _controller.animateTo(scaleFactor, duration: const Duration(milliseconds: 80));
    visible = buffering;
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInCubic,
      ),
      axis: Axis.horizontal,
      axisAlignment: 0,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(1, 1, 8, 3),
        child: SizedBox(
          width: 10,
          height: 10,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}
