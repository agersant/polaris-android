package agersant.polaris.api.remote;


import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.ItemsCallback;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.HttpUrl;
import okhttp3.MediaType;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okio.BufferedSink;

public class APIVersion2 extends APIBase
		implements IRemoteAPI {

	private final Gson gson;

	APIVersion2(DownloadQueue downloadQueue, RequestQueue requestQueue) {
		super(downloadQueue, requestQueue);
		this.gson = new GsonBuilder()
				.registerTypeAdapter(CollectionItem.class, new CollectionItem.Deserializer())
				.registerTypeAdapter(CollectionItem.Directory.class, new CollectionItem.Directory.Deserializer())
				.registerTypeAdapter(CollectionItem.Song.class, new CollectionItem.Song.Deserializer())
				.create();
	}

	String getAudioURL(String path) {
		String serverAddress = ServerAPI.getAPIRootURL();
		return serverAddress + "/serve/" + path;
	}

	String getThumbnailURL(String path) {
		String serverAddress = ServerAPI.getAPIRootURL();
		return serverAddress + "/serve/" + path;
	}

	public void browse(String path, final ItemsCallback handlers) {
		String requestURL = ServerAPI.getAPIRootURL() + "/browse/" + path;
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
				if (response.body() == null) {
					handlers.onError();
					return;
				}

				Type collectionType = new TypeToken<ArrayList<CollectionItem>>() {}.getType();
				ArrayList<CollectionItem> items;
				try {
					items = gson.fromJson(response.body().charStream(), collectionType);
				} catch (JsonSyntaxException e) {
					handlers.onError();
					return;
				}
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}

	void getAlbums(String url, final ItemsCallback handlers) {
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
				if (response.body() == null) {
					handlers.onError();
					return;
				}

				Type collectionType = new TypeToken<ArrayList<CollectionItem.Directory>>() {}.getType();
				ArrayList<? extends CollectionItem> items;
				try {
					items = gson.fromJson(response.body().charStream(), collectionType);
				} catch (JsonSyntaxException e) {
					handlers.onError();
					return;
				}
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}

	public void flatten(String path, final ItemsCallback handlers) {
		String requestURL = ServerAPI.getAPIRootURL() + "/flatten/" + path;
		Request request = new Request.Builder().url(requestURL).build();
		Callback callback = new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
				handlers.onError();
			}

			@Override
			public void onResponse(Call call, Response response) {
				if (response.body() == null) {
					handlers.onError();
					return;
				}

				Type collectionType = new TypeToken<ArrayList<CollectionItem.Song>>() {}.getType();
				ArrayList<? extends CollectionItem> items;
				try {
					items = gson.fromJson(response.body().charStream(), collectionType);
				} catch (JsonSyntaxException e) {
					handlers.onError();
					return;
				}
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}

	public void setLastFMNowPlaying(String path) {
		String requestURL = ServerAPI.getAPIRootURL() + "/lastfm/now_playing/" + path;
		Request request = new Request.Builder().url(requestURL).put(new RequestBody() {
			@Override
			public MediaType contentType() {
				return null;
			}
			@Override
			public void writeTo(BufferedSink sink) {

			}
		}).build();

		requestQueue.requestAsync(request, new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
			}
			@Override
			public void onResponse(Call call, Response response) {
			}
		});
	}

	public void scrobbleOnLastFM(String path) {

		String requestURL = ServerAPI.getAPIRootURL() + "/lastfm/scrobble/" + path;

		Request request = new Request.Builder().url(requestURL).post(new RequestBody() {
			@Override
			public MediaType contentType() {
				return null;
			}
			@Override
			public void writeTo(BufferedSink sink) {

			}
		}).build();

		requestQueue.requestAsync(request, new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
			}
			@Override
			public void onResponse(Call call, Response response) {
			}
		});
	}
}

