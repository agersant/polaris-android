package agersant.polaris.api;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.media.MediaDataSource;
import android.preference.PreferenceManager;
import android.widget.ImageView;

import com.android.volley.Response;

import java.io.IOException;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.api.local.ImageCache;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.local.OfflineCache;
import agersant.polaris.api.remote.ServerAPI;

/**
 * Created by agersant on 12/25/2016.
 */

public class API {

	private static API instance;
	private ServerAPI serverAPI;
	private LocalAPI localAPI;
	private SharedPreferences preferences;
	private String offlineModePreferenceKey;

	private API(Context context) {
		preferences = PreferenceManager.getDefaultSharedPreferences(context);
		offlineModePreferenceKey = context.getString(R.string.pref_key_offline);
		serverAPI = ServerAPI.getInstance();
		localAPI = LocalAPI.getInstance();
	}

	public static void init(Context context) {
		instance = new API(context);
	}

	public static API getInstance() {
		return instance;
	}

	public boolean isOffline() {
		return preferences.getBoolean(offlineModePreferenceKey, false);
	}

	public MediaDataSource getAudio(CollectionItem item) throws IOException {
		if (localAPI.hasAudio(item)) {
			return localAPI.getAudio(item);
		}
		return getAPI().getAudio(item);
	}

	public void getImage(CollectionItem item, ImageView view) {
		{
			String artworkPath = item.getArtwork();
			if (artworkPath == null) {
				return;
			}

			ImageCache cache = ImageCache.getInstance();
			Bitmap cacheEntry = cache.get(artworkPath);
			if (cacheEntry != null) {
				OfflineCache.getInstance().put(item, null, cacheEntry);
				view.setImageBitmap(cacheEntry);
				return;
			}
		}
		if (localAPI.hasImage(item)) {
			localAPI.getImage(item, view);
		}
		getAPI().getImage(item, view);
	}

	public void browse(String path, final Response.Listener<ArrayList<CollectionItem>> success, Response.ErrorListener failure) {
		getAPI().browse(path, success, failure);
	}

	private IPolarisAPI getAPI() {
		if (isOffline()) {
			return localAPI;
		}
		return serverAPI;
	}

}
