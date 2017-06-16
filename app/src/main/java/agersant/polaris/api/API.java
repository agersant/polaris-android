package agersant.polaris.api;

import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.preference.PreferenceManager;
import android.widget.ImageView;

import com.google.android.exoplayer2.source.MediaSource;

import java.io.IOException;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;
import agersant.polaris.api.local.ImageCache;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.remote.ServerAPI;


public class API {

	private final ServerAPI serverAPI;
	private final LocalAPI localAPI;
	private final SharedPreferences preferences;
	private final String offlineModePreferenceKey;
	private final PolarisService service;

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

	public MediaSource getAudio(CollectionItem item) throws IOException {
		if (localAPI.hasAudio(item)) {
			return localAPI.getAudio(item);
		}
		return getAPI().getAudio(item);
	}

	public void getImage(CollectionItem item, ImageView view) {
		String artworkPath = item.getArtwork();
		if (artworkPath == null) {
			return;
		}
		ImageCache cache = ImageCache.getInstance();
		Bitmap bitmap = cache.get(artworkPath);
		if (bitmap != null){
			view.setImageBitmap(bitmap);
			return;
		}
		FetchImageTask.load(service, item, view);
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
