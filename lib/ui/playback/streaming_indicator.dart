import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';

final getIt = GetIt.instance;

class StreamingIndicator extends StatelessWidget {
  const StreamingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: getIt<AudioPlayer>().playerStateStream,
      builder: (context, snapshot) {
        final bool isBuffering = snapshot.data?.processingState != ProcessingState.ready &&
            snapshot.data?.processingState != ProcessingState.completed;
        if (!isBuffering) {
          return Container();
        }
        return const Padding(
          padding: EdgeInsets.only(right: 8, bottom: 2),
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
        );
      },
    );
  }
}
