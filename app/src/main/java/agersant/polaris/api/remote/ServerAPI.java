package agersant.polaris.api.remote;


import android.content.Context;
import android.content.SharedPreferences;
import android.media.MediaDataSource;
import android.preference.PreferenceManager;
import android.widget.ImageView;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeoutException;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.api.IPolarisAPI;
import agersant.polaris.api.ItemsCallback;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

public class ServerAPI
		implements IPolarisAPI {

	private static ServerAPI instance;
	private final RequestQueue requestQueue;
	private final Gson gson;
	private final SharedPreferences preferences;
	private final String serverAddressKey;

	private ServerAPI(Context context) {
		this.serverAddressKey = context.getString(R.string.pref_key_server_url);
		this.preferences = PreferenceManager.getDefaultSharedPreferences(context);
		this.requestQueue = RequestQueue.getInstance();
		this.gson = new GsonBuilder()
				.registerTypeAdapter(CollectionItem.class, new CollectionItem.Deserializer())
				.registerTypeAdapter(CollectionItem.Directory.class, new CollectionItem.Directory.Deserializer())
				.registerTypeAdapter(CollectionItem.Song.class, new CollectionItem.Song.Deserializer())
				.create();
	}

	public static void init(Context context) {
		instance = new ServerAPI(context);
	}

	public static ServerAPI getInstance() {
		return instance;
	}

	String getURL() {
		String address = this.preferences.getString(serverAddressKey, "");
		address = address.replaceAll("/$", "");
		return address + "/api";
	}

	private String getMediaURL(String path) {
		String serverAddress = this.getURL();
		return serverAddress + "/serve/" + path;
	}

	@Override
	public MediaDataSource getAudio(CollectionItem item) throws IOException {
		DownloadQueue downloadQueue = DownloadQueue.getInstance();
		return downloadQueue.getAudio(item);
	}

	@Override
	public void getImage(CollectionItem item, ImageView view) {
		FetchImageTask.load(item, view);
	}

	ResponseBody serve(String path) throws InterruptedException, ExecutionException, TimeoutException, IOException {
		String url = getMediaURL(path);
		Request request = new Request.Builder().url(url).build();
		return requestQueue.requestSync(request);
	}

	public void browse(String path, final ItemsCallback handlers) {
		String serverAddress = this.getURL();
		String requestURL = serverAddress + "/browse/" + path;
		Request request = new Request.Builder().url(requestURL).build();
		Callback callback = new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
				handlers.onError();
			}

			@Override
			public void onResponse(Call call, Response response) throws IOException {
				Type collectionType = new TypeToken<ArrayList<CollectionItem>>() {
				}.getType();
				ArrayList<CollectionItem> items = gson.fromJson(response.body().string(), collectionType);
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}

	public void getRandomAlbums(final ItemsCallback handlers) {
		String serverAddress = this.getURL();
		String requestURL = serverAddress + "/random/";
		Request request = new Request.Builder().url(requestURL).build();
		Callback callback = new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
				handlers.onError();
			}

			@Override
			public void onResponse(Call call, Response response) throws IOException {
				Type collectionType = new TypeToken<ArrayList<CollectionItem.Directory>>() {
				}.getType();
				ArrayList<CollectionItem.Directory> directories = gson.fromJson(response.body().string(), collectionType);
				ArrayList<? extends CollectionItem> items = directories;
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}

	public void flatten(String path, final ItemsCallback handlers) {
		String serverAddress = this.getURL();
		String requestURL = serverAddress + "/flatten/" + path;
		Request request = new Request.Builder().url(requestURL).build();
		Callback callback = new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
				handlers.onError();
			}

			@Override
			public void onResponse(Call call, Response response) throws IOException {
				Type collectionType = new TypeToken<ArrayList<CollectionItem.Song>>() {
				}.getType();
				ArrayList<CollectionItem.Song> songs = gson.fromJson(response.body().string(), collectionType);
				ArrayList<? extends CollectionItem> items = songs;
				handlers.onSuccess(items);
			}
		};
		requestQueue.requestAsync(request, callback);
	}
}

