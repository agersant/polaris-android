enum APIError {
  unspecifiedHost,
  networkError,
  unauthorized,
  responseParseError,
  requestFailed,
  timeout,
  notImplemented,
  unexpectedCacheMiss,
}

const apiVersionEndpoint = '/api/version/';
const browseEndpoint = '/api/browse/';
const flattenEndpoint = '/api/flatten/';
const songsEndpoint = '/api/songs/';
const loginEndpoint = '/api/auth/';
const thumbnailEndpoint = '/api/thumbnail/';
const audioEndpoint = '/api/audio/';

String albumEndpoint(String name, List<String> mainArtists) =>
    '/api/album/${Uri.encodeComponent(name)}/by/${Uri.encodeComponent(mainArtists.join('\u000c'))}';

String randomEndpoint(int apiVersion) => apiVersion == 8 ? '/api/albums/random/' : '/api/random';

String recentEndpoint(int apiVersion) => apiVersion == 8 ? '/api/albums/recent/' : '/api/recent';

String searchEndpoint(String query) => '/api/search/${Uri.encodeComponent(query)}';
