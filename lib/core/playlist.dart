import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:uuid/uuid.dart';

class Playlist {
  ConcatenatingAudioSource _audioSource = ConcatenatingAudioSource(children: []);
  final Uuid uuid;
  final connection.Manager connectionManager;
  final polaris.Client polarisClient;
  final AudioPlayer audioPlayer;

  ConcatenatingAudioSource get audioSource => _audioSource;

  Playlist({
    required this.uuid,
    required this.connectionManager,
    required this.polarisClient,
    required this.audioPlayer,
  }) {
    connectionManager.addListener(() {
      if (connectionManager.state == connection.State.disconnected) {
        clear();
      }
    });
  }

  Future queueLast(List<dto.Song> songs, {bool autoPlay = true}) async {
    final bool wasEmpty = _audioSource.sequence.isEmpty;
    await _audioSource.addAll(await _makeAudioSources(songs));
    if (wasEmpty && autoPlay) {
      audioPlayer.play();
    }
  }

  Future queueNext(List<dto.Song> songs) async {
    final bool wasEmpty = _audioSource.sequence.isEmpty;
    final int insertIndex = wasEmpty ? 0 : 1 + (audioPlayer.currentIndex ?? -1);
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
    await _audioSource.move(oldIndex, insertIndex);
  }

  Future removeSong(int index) async {
    await _audioSource.removeAt(index);
  }

  Future clear() async {
    _audioSource = ConcatenatingAudioSource(children: []);
    await audioPlayer.setAudioSource(_audioSource);
  }

  List<dto.Song> getSongs() {
    return _audioSource.sequence.map((e) => (e.tag as MediaItem?)?.toSong()).whereType<dto.Song>().toList();
  }

  Future<List<AudioSource>> _makeAudioSources(List<dto.Song> songs) async {
    final futureAudioSources = songs.map((s) async => await polarisClient.getAudio(s, uuid.v4()));
    return (await Future.wait(futureAudioSources)).whereType<AudioSource>().toList();
  }
}
