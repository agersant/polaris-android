package agersant.polaris.api;

import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.net.Uri;
import android.preference.PreferenceManager;
import android.widget.ImageView;

import java.io.IOException;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;
import agersant.polaris.api.local.ImageCache;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.remote.ServerAPI;

/**
 * Created by agersant on 12/25/2016.
 */

public class API {

	private ServerAPI serverAPI;
	private LocalAPI localAPI;
	private SharedPreferences preferences;
	private String offlineModePreferenceKey;
	private PolarisService service;

	public API(PolarisService service, ServerAPI serverAPI, LocalAPI localAPI) {
		this.service = service;
		this.serverAPI = serverAPI;
		this.localAPI = localAPI;
		preferences = PreferenceManager.getDefaultSharedPreferences(service);
		offlineModePreferenceKey = service.getString(R.string.pref_key_offline);
	}

	public boolean isOffline() {
		return preferences.getBoolean(offlineModePreferenceKey, false);
	}

	public Uri getAudio(CollectionItem item) throws IOException {
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
				service.saveImage(item, cacheEntry);
				view.setImageBitmap(cacheEntry);
				return;
			}
		}
		if (localAPI.hasImage(item)) {
			localAPI.getImage(item, view);
		}
		getAPI().getImage(item, view);
	}

	public void browse(String path, ItemsCallback handlers) {
		getAPI().browse(path, handlers);
	}

	public void flatten(String path, ItemsCallback handlers) {
		getAPI().flatten(path, handlers);
	}

	private IPolarisAPI getAPI() {
		if (isOffline()) {
			return localAPI;
		}
		return serverAPI;
	}

}
