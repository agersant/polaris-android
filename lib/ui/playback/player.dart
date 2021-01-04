import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/playback/media_item.dart';
import 'package:polaris/playback/media_proxy.dart';
import 'package:polaris/playback/player_task.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/thumbnail.dart';
import 'package:rxdart/rxdart.dart';

final getIt = GetIt.instance;

class Player extends StatefulWidget {
  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  @override
  void initState() {
    super.initState();
    // TODO determine if we ever need to stop this
    AudioService.start(
      backgroundTaskEntrypoint: audioPlayerTaskEntrypoint,
      androidNotificationChannelName: appName,
      androidNotificationColor: Colors.blue[400].value, // TODO evaluate where this goes and how it looks
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidEnableQueue: true,
      params: {
        MediaProxy.portParam: getIt<MediaProxy>().port,
      },
    );
  }

  Stream<PlaybackState> get _mediaStateStream => Rx.combineLatest2<MediaItem, Duration, PlaybackState>(
      AudioService.currentMediaItemStream,
      AudioService.positionStream,
      (mediaItem, position) => PlaybackState(mediaItem.toSong(), position));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
        stream: _mediaStateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(); // TODO animate the whole thing out when no data
          }
          final state = snapshot.data;
          return SizedBox(
              height: 64,
              child: Material(
                child: Container(
                  color: Theme.of(context).backgroundColor, // TODO ugly
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListThumbnail(state.song.artwork),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.song.title, style: Theme.of(context).textTheme.subtitle1),
                            Text(state.song.artist, style: Theme.of(context).textTheme.caption),
                          ],
                        ),
                      ),
                      StreamBuilder<bool>(
                        stream: AudioService.playbackStateStream.map((state) => state.playing).distinct(),
                        builder: (context, snapshot) {
                          final playing = snapshot.data ?? false;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (playing) pauseButton() else playButton(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ));
        });
  }
}

IconButton pauseButton() => IconButton(
      icon: Icon(Icons.pause),
      iconSize: 24.0,
      onPressed: AudioService.pause,
    );

IconButton playButton() => IconButton(
      icon: Icon(Icons.play_arrow),
      iconSize: 24.0,
      onPressed: AudioService.play,
    );

class PlaybackState {
  final Song song;
  final Duration position;

  PlaybackState(this.song, this.position);
}
