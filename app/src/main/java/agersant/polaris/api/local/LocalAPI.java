package agersant.polaris.api.local;

import android.graphics.Bitmap;
import android.media.MediaDataSource;
import android.widget.ImageView;

import com.android.volley.Response;

import java.io.IOException;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.IPolarisAPI;

/**
 * Created by agersant on 12/25/2016.
 */

public class LocalAPI implements IPolarisAPI {

	private static LocalAPI instance;

	private LocalAPI() {

	}

	public static void init() {
		instance = new LocalAPI();
	}

	public static LocalAPI getInstance() {
		return instance;
	}

	public boolean hasAudio(CollectionItem item) {
		OfflineCache offlineCache = OfflineCache.getInstance();
		String path = item.getPath();
		return offlineCache.hasAudio(path);
	}

	@Override
	public MediaDataSource getAudio(CollectionItem item) throws IOException {
		OfflineCache offlineCache = OfflineCache.getInstance();
		String path = item.getPath();
		return offlineCache.getAudio(path);
	}

	public boolean hasImage(CollectionItem item) {
		OfflineCache offlineCache = OfflineCache.getInstance();
		String path = item.getPath();
		return offlineCache.hasImage(path);
	}

	@Override
	public void getImage(CollectionItem item, ImageView view) {
		OfflineCache offlineCache = OfflineCache.getInstance();
		String path = item.getPath();
		try {
			Bitmap image = offlineCache.getImage(path);
			view.setImageBitmap(image);

			ImageCache imageCache = ImageCache.getInstance();
			String artworkPath = item.getArtwork();
			imageCache.put(artworkPath, image);
		} catch (IOException e) {
		}
	}

	public void browse(String path, Response.Listener<ArrayList<CollectionItem>> success, Response.ErrorListener failure) {
		OfflineCache offlineCache = OfflineCache.getInstance();
		ArrayList<CollectionItem> items = offlineCache.browse(path);
		if (items == null) {
			failure.onErrorResponse(null);
		} else {
			success.onResponse(items);
		}
	}
}
