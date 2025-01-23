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
const randomEndpoint = '/api/albums/random/';
const recentEndpoint = '/api/albums/recent/';
const loginEndpoint = '/api/auth/';
const thumbnailEndpoint = '/api/thumbnail/';
const audioEndpoint = '/api/audio/';
