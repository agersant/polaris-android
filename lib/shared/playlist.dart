import 'package:just_audio/just_audio.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/media_item.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:uuid/uuid.dart';

class Playlist {
  final _audioSource = new ConcatenatingAudioSource(children: []);
  final Uuid uuid;
  final polaris.API polarisAPI;
  final AudioPlayer audioPlayer;

  AudioSource get audioSource => _audioSource;

  Playlist({
    required this.uuid,
    required this.polarisAPI,
    required this.audioPlayer,
  });

  Future queueLast(Song song) async {
    final songAudioSource = _makeSongAudioSource(song);
    return _audioSource.add(songAudioSource);
  }

  Future queueNext(Song song) async {
    final songAudioSource = _makeSongAudioSource(song);
    final int insertIndex = 1 + (audioPlayer.currentIndex ?? -1);
    return _audioSource.insert(insertIndex, songAudioSource);
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

  AudioSource _makeSongAudioSource(Song song) {
    final songURI = polarisAPI.getAudioURI(song.path);
    final mediaItem = song.toMediaItem(uuid, polarisAPI);
    return AudioSource.uri(songURI, tag: mediaItem);
  }
}
