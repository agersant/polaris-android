import 'package:flutter/material.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

const exampleArt = 'Leviathan/OST - Anime/Howl\'s Moving Castle/2004 - Howl\'s Moving Castle Soundtrack/Folder.jpg';

class PlayerPage extends StatelessWidget {
  const PlayerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(nowPlaying),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline))], // TODO implement info button
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Material(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        child: LargeThumbnail(exampleArt), // TODO dynamic art
                        elevation: 2,
                      ),
                    ),
                    Column(
                      children: [
                        // TODO real track info
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Another World', style: Theme.of(context).textTheme.bodyText1),
                        ),
                        Text('Atsushi Kitajoh', style: Theme.of(context).textTheme.caption),
                        // TODO real slider progress
                        // TODO slider interactions
                        Slider(value: .25, onChanged: (value) {}),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // TODO real timing information
                              Text('0:39', style: Theme.of(context).textTheme.caption),
                              Text('1:44', style: Theme.of(context).textTheme.caption),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // TODO button interactions
                            IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.pause)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            OutlinedButton(
              onPressed: getIt<PagesModel>().openQueue,
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 16),
                    child: Text('Up Next', style: Theme.of(context).textTheme.overline),
                  ),
                  const ListTile(
                    // TODO real-queue information
                    leading: ListThumbnail(exampleArt),
                    title: Text('After the Rain'),
                    subtitle: Text('Joe Hisaishi'),
                    trailing: Icon(Icons.queue_music),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
