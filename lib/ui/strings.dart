const appName = 'Polaris';

// Errors
const errorAPIVersion = 'The Polaris server responded but uses an incompatible API version.';
const errorNetwork = 'The Polaris server could not be reached.';
const errorRequestFailed = 'The Polaris server sent an unexpected response.';
const errorTimeout = 'The Polaris server is taking too long to respond.';
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

// Collection tabs
const tabFiles = 'FILES';
const tabAlbums = 'ALBUMS';
const tabArtists = 'ARTISTS';
const tabGenres = 'GENRES';
const tabPlaylists = 'PLAYLISTS';
const tabSearch = 'SEARCH';

// Collection
const albumDetailsError = 'There was an error while reading this album.';
const albumsError = 'There was an error while listing albums.';
const artistError = 'There was an error while reading artist information.';
const artistGenres = 'Genres';
const artistMainAlbums = 'Releases';
const artistOtherAlbums = 'Featured On';
const artistsError = 'There was an error while listing artists.';
const browseError = 'There was an error while reading this directory.';
const collectionTitle = 'Collection';
const emptyAlbum = 'There are no songs on this album.';
const emptyAlbumList = 'There are no albums to display.';
const emptyDirectory = 'There is nothing in this directory.';
const filterFieldLabel = 'Filter';
const genreAlbums = 'Albums';
const genreAlbumsError = 'There was an error while listing albums.';
const genreArtists = 'Artists';
const genreArtistsError = 'There was an error while listing artists.';
const genreError = 'There was an error while reading genre information.';
const genreMainArtists = 'Main Artists';
const genreOverview = 'Overview';
const genreRecentlyAdded = 'Recently Added';
const genreRelated = 'Related Genres';
const genresError = 'There was an error while listing genres.';
const goBackButtonLabel = 'GO BACK';
const listPlaylistsError = 'There was an error while listing playlists.';
const noArtists = 'No artists match this filter.';
const noGenres = 'No genres match this filter.';
const noSavedPlaylists = 'You have not saved any playlists';
const noSearchResults = 'No songs were found.';
const playAllButtonLabel = 'Play All';
const playButtonLabel = 'Play';
const queueAllButtonLabel = 'Queue All';
const queueButtonLabel = 'Queue';
const randomAlbums = 'RANDOM';
const recentAlbums = 'RECENT';
const roleComposer = 'COMPOSERS';
const roleLyricist = 'LYRICISTS';
const rolePerformer = 'PERFORMERS';
const searchError = 'There was an error while searching for songs.';
const unknownAlbum = 'Unknown Album';
const unknownArtist = 'Unknown Artist';
const unknownSong = 'Unknown Song';
String numSearchResults(int? n) => '${n ?? "?"} ${(n ?? 2) > 1 ? "results" : "result"}';

// Context menu
const contextMenuQueueLast = 'Play Last';
const contextMenuQueueNext = 'Play Next';
const contextMenuRefresh = 'Refresh';
const contextMenuRemoveFromQueue = 'Remove';
const contextMenuPin = 'Add to Offline Music';
const contextMenuUnpin = 'Remove from Offline Music';
const contextMenuSongInfo = 'Song Details';
const contextMenuDeletePlaylist = 'Delete Playlist';
const contextMenuViewAlbum = 'View Album';
const contextMenuViewFolder = 'View Folder';

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
const queueSavePopupTitle = 'Playlist Name';
const queueSave = 'Save';
const queueSaveCancel = 'Cancel';
const nowPlaying = 'Now Playing';
const upNext = 'Up Next';
const upNextNothing = 'End of the queue';
const upNextNothingSubtitle = 'No upcoming song';

// Song info
const songInfoPopupTitle = 'Song Details';
const songInfoAlbum = 'Album';
const songInfoAlbumArtist = 'Album Artist';
const songInfoArtist = 'Artist';
const songInfoComposer = 'Composer';
const songInfoDiscNumber = 'Disc Number';
const songInfoDuration = 'Duration';
const songInfoGenre = 'Genre';
const songInfoLabel = 'Label';
const songInfoLyricist = 'Lyricist';
const songInfoTitle = 'Title';
const songInfoTrackNumber = 'Track Number';
const songInfoYear = 'Year';
const songInfoCloseButton = 'Close';

// Offline music
const offlineMusicTitle = 'Offline Music';
const offlineMusicEmpty = 'You have not saved any music.';
String xySongs(int? x, int? y) => '${x ?? "?"}/${y ?? "?"} ${(y ?? 2) > 1 ? "songs" : "song"}';
String nSongs(int? n) => '${n ?? "?"} ${(n ?? 2) > 1 ? "songs" : "song"}';

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
