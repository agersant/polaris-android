import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/media_item.dart';
import 'package:uuid/uuid.dart';

class Playlist {
  String? _name;
  ConcatenatingAudioSource _audioSource = ConcatenatingAudioSource(children: []);
  final Uuid uuid;
  final connection.Manager connectionManager;
  final AppClient appClient;
  final AudioPlayer audioPlayer;

  String? get name => _name;
  ConcatenatingAudioSource get audioSource => _audioSource;

  Playlist({
    required this.uuid,
    required this.connectionManager,
    required this.appClient,
    required this.audioPlayer,
  }) {
    connectionManager.addListener(() {
      if (connectionManager.state == connection.State.disconnected) {
        clear();
      }
    });
  }

  Future queueLast(List<String> songs, {bool autoPlay = true}) async {
    final bool wasEmpty = _audioSource.sequence.isEmpty;
    await _audioSource.addAll(await _makeAudioSources(songs));
    if (wasEmpty && autoPlay) {
      audioPlayer.play();
    }
  }

  Future queueNext(List<String> songs) async {
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

  setName(String? newName) {
    _name = newName;
  }

  Future clear() async {
    _name = null;
    _audioSource = ConcatenatingAudioSource(children: []);
    await audioPlayer.setAudioSource(_audioSource);
  }

  List<String> getSongs() {
    return _audioSource.sequence.map((e) => (e.tag as MediaItem).getSongPath()).toList().cast<String>();
  }

  Future<List<AudioSource>> _makeAudioSources(List<String> songs) async {
    final futureAudioSources = songs.map((s) async => await appClient.getAudio(s, uuid.v4()));
    return (await Future.wait(futureAudioSources)).whereType<AudioSource>().toList();
  }
}
