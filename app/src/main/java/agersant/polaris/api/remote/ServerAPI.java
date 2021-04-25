package agersant.polaris.api.remote;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.preference.PreferenceManager;

import com.google.android.exoplayer2.source.MediaSource;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.api.ItemsCallback;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

public class ServerAPI implements IRemoteAPI {

    static private String serverAddressKey;
    static private SharedPreferences preferences;
    private final OkHttpClient client;
    private DownloadQueue downloadQueue;
    private IRemoteAPI currentVersion;
    private final Auth auth;

    public ServerAPI(Context context) {
        final ServerAPI that = this;
        serverAddressKey = context.getString(R.string.pref_key_server_url);
        preferences = PreferenceManager.getDefaultSharedPreferences(context);
        preferences.registerOnSharedPreferenceChangeListener((SharedPreferences sharedPreferences, String key) -> that.currentVersion = null);
        client = new OkHttpClient.Builder().retryOnConnectionFailure(true).build();
        this.auth = new Auth(context);
    }

    public void initialize(DownloadQueue downloadQueue) {
        this.downloadQueue = downloadQueue;
    }

    static String getAPIRootURL() {
        String address = preferences.getString(serverAddressKey, "");
        address = address.trim();
        if (!(address.startsWith("http://") || address.startsWith("https://"))) {
            address = "http://" + address;
        }
        address = address.replaceAll("/$", "");
        return address + "/api";
    }

    private void handleAPIVersionResponse(Response response) {
        if (!response.isSuccessful()) {
            return;
        }

        if (response.body() == null) {
            return;
        }

        Type versionType = new TypeToken<APIVersion>() {
        }.getType();
        APIVersion version;
        try {
            Gson gson = new GsonBuilder().create();
            version = gson.fromJson(response.body().charStream(), versionType);
        } catch (JsonSyntaxException e) {
            System.out.println("Error parsing API version " + e);
            return;
        }

        currentVersion = selectImplementation(version);
    }

    private Request getVersionRequest() {
        return new Request.Builder().url(getAPIRootURL() + "/version").build();
    }

    private void fetchAPIVersion() {
        if (currentVersion != null) {
            return;
        }
        try {
            Response response = client.newCall(getVersionRequest()).execute();
            handleAPIVersionResponse(response);
        } catch (IOException e) {
            System.out.println("Error fetching API version " + e);
        }
    }

    private void fetchAPIVersionAsync(VersionCallback callback) {
        if (currentVersion != null) {
            callback.onSuccess();
            return;
        }

        final ServerAPI that = this;

        client.newCall(getVersionRequest()).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                System.out.println("Error fetching API version " + e);
                callback.onError();
            }

            @Override
            public void onResponse(Call call, Response response) {
                that.handleAPIVersionResponse(response);
                if (currentVersion == null) {
                    callback.onError();
                } else {
                    callback.onSuccess();
                }
            }
        });
    }

    Auth getAuth() {
        return auth;
    }

    private IRemoteAPI selectImplementation(APIVersion version) {
        RequestQueue requestQueue = new RequestQueue(auth);
        if (version.major < 3) {
            return new APIVersion2(downloadQueue, requestQueue);
        }
        if (version.major < 4) {
            return new APIVersion3(downloadQueue, requestQueue);
        }
        if (version.major < 5) {
            return new APIVersion4(downloadQueue, requestQueue);
        }
        return new APIVersion5(downloadQueue, requestQueue);
    }

    public void getRandomAlbums(ItemsCallback handlers) {
        fetchAPIVersionAsync(new VersionCallback() {
            @Override
            public void onSuccess() {
                currentVersion.getRandomAlbums(handlers);
            }

            @Override
            public void onError() {
                handlers.onError();
            }
        });
    }

    public void getRecentAlbums(ItemsCallback handlers) {
        fetchAPIVersionAsync(new VersionCallback() {
            @Override
            public void onSuccess() {
                currentVersion.getRecentAlbums(handlers);
            }

            @Override
            public void onError() {
                handlers.onError();
            }
        });
    }

    public void setLastFMNowPlaying(String path) {
        fetchAPIVersionAsync(new VersionCallback() {
            @Override
            public void onSuccess() {
                currentVersion.setLastFMNowPlaying(path);
            }

            @Override
            public void onError() {
            }
        });
    }

    public void scrobbleOnLastFM(String path) {
        fetchAPIVersionAsync(new VersionCallback() {
            @Override
            public void onSuccess() {
                currentVersion.scrobbleOnLastFM(path);
            }

            @Override
            public void onError() {
            }
        });
    }

    public MediaSource getAudio(CollectionItem item) throws IOException {
        fetchAPIVersion();
        if (currentVersion != null) {
            return currentVersion.getAudio(item);
        }
        return null;
    }

    public ResponseBody getAudio(String path) throws IOException {
        fetchAPIVersion();
        if (currentVersion != null) {
            return currentVersion.getAudio(path);
        }
        return null;
    }

    public ResponseBody getThumbnail(String path) throws IOException {
        fetchAPIVersion();
        if (currentVersion != null) {
            return currentVersion.getThumbnail(path);
        }
        return null;
    }

    public Uri getAudioUri(String path) {
        fetchAPIVersion();
        if (currentVersion != null) {
            return currentVersion.getAudioUri(path);
        }
        return null;
    }

    public Uri getThumbnailUri(String path) {
        fetchAPIVersion();
        if (currentVersion != null) {
            return currentVersion.getThumbnailUri(path);
        }
        return null;
    }

    public void browse(String path, ItemsCallback handlers) {
        fetchAPIVersionAsync(new VersionCallback() {
            @Override
            public void onSuccess() {
                currentVersion.browse(path, handlers);
            }

            @Override
            public void onError() {
                handlers.onError();
            }
        });
    }

    public void flatten(String path, ItemsCallback handlers) {
        fetchAPIVersionAsync(new VersionCallback() {
            @Override
            public void onSuccess() {
                currentVersion.flatten(path, handlers);
            }

            @Override
            public void onError() {
                handlers.onError();
            }
        });
    }

    class APIVersion {
        int major;
        int minor;
    }

    interface VersionCallback {
        void onSuccess();

        void onError();
    }

}
