import 'package:just_audio/just_audio.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/media_item.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:uuid/uuid.dart';

class Playlist {
  final _audioSource = new ConcatenatingAudioSource(children: []);
  final Uuid uuid;
  final polaris.API polarisAPI;

  AudioSource get audioSource => _audioSource;

  Playlist({
    required this.uuid,
    required this.polarisAPI,
  });

  Future queueLast(Song song) async {
    final songURI = polarisAPI.getAudioURI(song.path);
    final mediaItem = song.toMediaItem(uuid, polarisAPI);
    return _audioSource.add(AudioSource.uri(songURI, tag: mediaItem));
  }

  Future queueNext(Song song) async {
    // TODO implement queueNext
    // _audioSource.insert(getIt<AudioPlayer>, audioSource)
    return queueLast(song);
  }

  Future moveSong(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= _audioSource.length ||
        newIndex < 0 ||
        newIndex > _audioSource.length) {
      return;
    }
    final int insertIndex = oldIndex > newIndex ? newIndex : newIndex - 1;
    return _audioSource.move(oldIndex, insertIndex);
  }
}
