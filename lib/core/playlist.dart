import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/dto.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:uuid/uuid.dart';

class Playlist {
  final _audioSource = ConcatenatingAudioSource(children: []);
  final Uuid uuid;
  final polaris.Client polarisClient;
  final AudioPlayer audioPlayer;

  ConcatenatingAudioSource get audioSource => _audioSource;

  Playlist({
    required this.uuid,
    required this.polarisClient,
    required this.audioPlayer,
  });

  Future queueLast(List<Song> songs) async {
    final bool wasEmpty = _audioSource.sequence.isEmpty;
    await _audioSource.addAll(await _makeAudioSources(songs));
    if (wasEmpty) {
      audioPlayer.play();
    }
  }

  Future queueNext(List<Song> songs) async {
    final bool wasEmpty = _audioSource.sequence.isEmpty;
    final int insertIndex = 1 + (audioPlayer.currentIndex ?? -1);
    await _audioSource.insertAll(insertIndex, await _makeAudioSources(songs));
    if (wasEmpty) {
      audioPlayer.play();
    }
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

  Future<List<AudioSource>> _makeAudioSources(List<Song> songs) async {
    final futureAudioSources = songs.map((s) async => await polarisClient.getAudio(s, uuid.v4()));
    return (await Future.wait(futureAudioSources)).whereType<AudioSource>().toList();
  }
}
