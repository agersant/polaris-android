package agersant.polaris.api;

import android.content.SharedPreferences;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.preference.PreferenceManager;
import android.widget.ImageView;

import com.google.android.exoplayer2.source.MediaSource;

import junit.framework.Assert;

import java.io.IOException;
import java.lang.ref.WeakReference;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisApplication;
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

	public void loadImage(CollectionItem item, FetchImageTask.Callback callback) {
		String artworkPath = item.getArtwork();
		Assert.assertNotNull(artworkPath);
		ImageCache cache = ImageCache.getInstance();
		Bitmap bitmap = cache.get(artworkPath);
		if (bitmap != null) {
			callback.onSuccess(bitmap);
			return;
		}
		FetchImageTask.load(service, item, callback);
	}

	public void loadImageIntoView(final CollectionItem item, ImageView view) {

		PolarisApplication polarisApplication = PolarisApplication.getInstance();
		Resources resources = polarisApplication.getResources();
		FetchImageTask.AsyncDrawable asyncDrawable = new FetchImageTask.AsyncDrawable(resources, item);
		view.setImageDrawable(asyncDrawable);

		final WeakReference<ImageView> imageViewReference = new WeakReference<>(view);
		loadImage(item, new FetchImageTask.Callback() {
			@Override
			public void onSuccess(Bitmap bitmap) {
				Assert.assertNotNull(bitmap);
				ImageView imageView = imageViewReference.get();
				if (imageView == null) {
					return;
				}
				Drawable drawable = imageView.getDrawable();
				if (!(drawable instanceof FetchImageTask.AsyncDrawable)) {
					return;
				}
				FetchImageTask.AsyncDrawable asyncDrawable = (FetchImageTask.AsyncDrawable) drawable;
				if (asyncDrawable.getItem() == item) {
					imageView.setImageBitmap(bitmap);
				}
			}
		});
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
