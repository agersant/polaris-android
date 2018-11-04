package agersant.polaris.api.remote;


import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.preference.PreferenceManager;
import android.widget.ImageView;

import com.google.android.exoplayer2.source.MediaSource;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.api.IPolarisAPI;
import agersant.polaris.api.ItemsCallback;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.HttpUrl;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

public class ServerAPI
		implements IPolarisAPI {

	private final RequestQueue requestQueue;
	private final Gson gson;
	private final SharedPreferences preferences;
	private final String serverAddressKey;
	private final Auth auth;
	private DownloadQueue downloadQueue;

	public ServerAPI(Context context) {
		this.serverAddressKey = context.getString(R.string.pref_key_server_url);
		this.preferences = PreferenceManager.getDefaultSharedPreferences(context);
		this.auth = new Auth(context);
		this.requestQueue = new RequestQueue(auth);
		this.gson = new GsonBuilder()
				.registerTypeAdapter(CollectionItem.class, new CollectionItem.Deserializer())
				.registerTypeAdapter(CollectionItem.Directory.class, new CollectionItem.Directory.Deserializer())
				.registerTypeAdapter(CollectionItem.Song.class, new CollectionItem.Song.Deserializer())
				.create();
	}

	public void initialize(DownloadQueue downloadQueue) {
		this.downloadQueue = downloadQueue;
	}

	public String getCookieHeader() {
		return auth.getCookieHeader();
	}

	public String getAuthorizationHeader() {
		return auth.getAuthorizationHeader();
	}

	private String getURL() {
		String address = this.preferences.getString(serverAddressKey, "");
		address = address.trim();
		if (!address.startsWith("http://")) {
			address = "http://" + address;
		}
		address = address.replaceAll("/$", "");
		return address + "/api";
	}

	private String getMediaURL(String path) {
		String serverAddress = this.getURL();
		return serverAddress + "/serve/" + path;
	}

	@Override
	public MediaSource getAudio(CollectionItem item) {
		return downloadQueue.getAudio(item);
	}

	Uri serveUri(String path) {
		String url = getMediaURL(path);
		return Uri.parse(url);
	}

	public ResponseBody serve(String path) throws IOException {
		Request request = new Request.Builder().url(serveUri(path).toString()).build();
		return requestQueue.requestSync(request);
	}

	public void browse(String path, final ItemsCallback handlers) {
		String requestURL = this.getURL() + "/browse/" + path;
		HttpUrl parsedURL = HttpUrl.parse(requestURL);
		if (parsedURL == null) {
			handlers.onError();
			return;
		}

		Request request = new Request.Builder().url(parsedURL).build();
		Callback callback = new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
				handlers.onError();
			}

			@Override
			public void onResponse(Call call, Response response) {
				Type collectionType = new TypeToken<ArrayList<CollectionItem>>() {
				}.getType();
				ArrayList<CollectionItem> items;
				try {
					items = gson.fromJson(response.body().string(), collectionType);
				} catch (Exception e) {
					handlers.onError();
					return;
				}
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}

	private void getAlbums(String url, final ItemsCallback handlers) {
		HttpUrl parsedURL = HttpUrl.parse(url);
		if (parsedURL == null) {
			handlers.onError();
			return;
		}

		Request request = new Request.Builder().url(parsedURL).build();
		Callback callback = new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
				handlers.onError();
			}

			@Override
			public void onResponse(Call call, Response response) {
				Type collectionType = new TypeToken<ArrayList<CollectionItem.Directory>>() {
				}.getType();
				ArrayList<? extends CollectionItem> items;
				try {
					items = gson.fromJson(response.body().string(), collectionType);
				} catch (Exception e) {
					handlers.onError();
					return;
				}
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}

	public void getRandomAlbums(ItemsCallback handlers) {
		String requestURL = this.getURL() + "/random/";
		getAlbums(requestURL, handlers);
	}

	public void getRecentAlbums(ItemsCallback handlers) {
		String requestURL = this.getURL() + "/recent/";
		getAlbums(requestURL, handlers);
	}

	public void flatten(String path, final ItemsCallback handlers) {
		String requestURL = this.getURL() + "/flatten/" + path;
		Request request = new Request.Builder().url(requestURL).build();
		Callback callback = new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
				handlers.onError();
			}

			@Override
			public void onResponse(Call call, Response response) {
				Type collectionType = new TypeToken<ArrayList<CollectionItem.Song>>() {
				}.getType();
				ArrayList<? extends CollectionItem> items;
				try {
					items = gson.fromJson(response.body().string(), collectionType);
				} catch (Exception e) {
					handlers.onError();
					return;
				}
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}
}

