import 'package:flutter/material.dart';
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/ui/strings.dart';

class SongInfoDialog extends StatelessWidget {
  final dto.Song song;

  static Future<void> openInfoDialog(BuildContext context, dto.Song song) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return SongInfoDialog(song);
      },
    );
  }

  const SongInfoDialog(this.song, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(songInfoPopupTitle),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            if (song.artist != null) ListTile(title: const Text(songInfoArtist), subtitle: Text(song.artist!)),
            if (song.title != null) ListTile(title: const Text(songInfoTitle), subtitle: Text(song.title!)),
            if (song.album != null) ListTile(title: const Text(songInfoAlbum), subtitle: Text(song.album!)),
            if (song.year != null) ListTile(title: const Text(songInfoYear), subtitle: Text(song.year!.toString())),
            if (song.genre != null) ListTile(title: const Text(songInfoGenre), subtitle: Text(song.genre!.toString())),
            if (song.composer != null)
              ListTile(title: const Text(songInfoComposer), subtitle: Text(song.composer!.toString())),
            if (song.lyricist != null)
              ListTile(title: const Text(songInfoLyricist), subtitle: Text(song.lyricist!.toString())),
            if (song.albumArtist != null)
              ListTile(title: const Text(songInfoAlbumArtist), subtitle: Text(song.albumArtist!.toString())),
            if (song.trackNumber != null)
              ListTile(title: const Text(songInfoTrackNumber), subtitle: Text(song.trackNumber!.toString())),
            if (song.discNumber != null)
              ListTile(title: const Text(songInfoDiscNumber), subtitle: Text(song.discNumber!.toString())),
            if (song.label != null) ListTile(title: const Text(songInfoLabel), subtitle: Text(song.label!.toString())),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text(songInfoCloseButton),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
