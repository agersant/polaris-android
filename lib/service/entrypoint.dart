import 'package:audio_service/audio_service.dart';
import 'package:polaris/service/audio_player.dart';

final String polarisHostParam = 'host';
final String polarisAuthTokenParam = 'authToken';

void entrypoint() async {
  AudioServiceBackground.run(() {
    return AudioPlayerTask();
  });
}
