const appName = 'Polaris';

// Errors
const errorAPIVersion = 'The Polaris server responded but uses an incompatible API version.';
const errorNetwork = 'The Polaris server could not be reached.';
const errorRequestFailed = 'The Polaris server sent an unexpected response.';
const errorUnknown = 'An unknown error occured.';
const errorAlreadyConnecting = 'Please wait while the connection is being established.';
const errorAlreadyAuthenticating = 'Please wait while the authentication is in progress.';
const errorIncorrectCredentials = 'Incorrect username or password.';
const retryButtonLabel = 'RETRY';

// Startup
const serverURLFieldLabel = 'Server URL';
const usernameFieldLabel = 'Username';
const passwordFieldLabel = 'Password';
const connectButtonLabel = 'CONNECT';
const disconnectButtonLabel = 'DISCONNECT';
const loginButtonLabel = 'LOGIN';
const offlineModeButtonLabel = 'BROWSE OFFLINE';

// Collection
const collectionTitle = 'Collection';
const collectionTabBrowseTitle = 'BROWSE';
const collectionTabRandomTitle = 'RANDOM';
const collectionTabRecentTitle = 'RECENT';
const unknownSong = 'Unknown Song';
const unknownAlbum = 'Unknown Album';
const unknownArtist = 'Unknown Artist';
const emptyDirectory = 'There is nothing in this directory.';
const emptyAlbumList = 'There are no albums to display.';
const emptyAlbum = 'There are no songs on this album.';
const browseError = 'There was an error while reading this directory.';
const randomError = 'There was an error while listing albums.';
const recentError = 'There was an error while listing albums.';
const albumDetailsError = 'There was an error while reading this album.';
const goBackButtonLabel = 'GO BACK';
const queueLast = 'Play Last';
const queueNext = 'Play Next';
const refresh = 'Refresh';
const pinFile = 'Add to Offline Music';
const unpinFile = 'Remove from Offline Music';

// Collection drawer
const drawerSettings = 'Settings';
const drawerOfflineMusic = 'Offline music';
const drawerOfflineMode = 'Offline mode';
const drawerLogOut = 'Log Out';
const unknownUser = 'Offline User';
const unknownHost = 'Unknown Host';

// Playback
const queueTitle = 'Queue';
const queueEmpty = 'There are no songs in the queue.';
const removeFromQueue = 'Remove';
const nowPlaying = 'Now Playing';

// Offline music
const offlineMusicTitle = 'Offline Music';
const offlineMusicEmpty = 'You have not saved any music.';
String xySongs(int? x, int? y) => '${x ?? "?"}/${y ?? "?"} ${(y ?? 2) > 1 ? "songs" : "song"}';
String nSongs(int? n) => '${n ?? "?"} ${(n ?? 2) > 1 ? "songs" : "song"}';
String nDirectories(int? n) => '${n ?? "?"} ${(n ?? 2) > 1 ? "directories" : "directory"}';

// Settings
const settingsTitle = 'Settings';
const appearanceHeader = 'APPEARANCE';
const theme = 'Theme';
const themeDescription = 'Your preferred visual style for this app.';
const themeLight = 'Light';
const themeDark = 'Dark';
const themeSystem = 'System';
const performanceHeader = 'PERFORMANCE';
const numberOfSongsToPreload = 'Playlist lookahead';
const numberOfSongsToPreloadDescription =
    'This setting controls how many upcoming songs in the playlist Polaris will download in advance.';
const cacheSize = 'Cache size';
const cacheSizeDescription =
    'This setting controls how much space Polaris is allowed to use to store recently used audio and image files.\nMusic in the queue, and music added to Offline Music do not count towards this limit.';
