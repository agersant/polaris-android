import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:polaris/playback/player_task.dart';

import '../strings.dart';

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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 48, child: Container(color: Colors.red));
  }
}
