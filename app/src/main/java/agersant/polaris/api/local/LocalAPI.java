package agersant.polaris.api.local;

import android.graphics.Bitmap;
import android.widget.ImageView;

import com.google.android.exoplayer2.source.MediaSource;

import java.io.IOException;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.IPolarisAPI;
import agersant.polaris.api.ItemsCallback;

/**
 * Created by agersant on 12/25/2016.
 */

public class LocalAPI implements IPolarisAPI {

	private OfflineCache offlineCache;

	public LocalAPI(OfflineCache offlineCache) {
		this.offlineCache = offlineCache;
	}

	public boolean hasAudio(CollectionItem item) {
		String path = item.getPath();
		return offlineCache.hasAudio(path);
	}

	@Override
	public MediaSource getAudio(CollectionItem item) throws IOException {
		String path = item.getPath();
		return offlineCache.getAudio(path);
	}

	public boolean hasImage(CollectionItem item) {
		String path = item.getPath();
		return offlineCache.hasImage(path);
	}

	@Override
	public void getImage(CollectionItem item, ImageView view) {
		String artworkPath = item.getArtwork();
		if (artworkPath == null) {
			return;
		}

		try {
			Bitmap image = offlineCache.getImage(artworkPath);
			view.setImageBitmap(image);

			ImageCache imageCache = ImageCache.getInstance();
			imageCache.put(artworkPath, image);
		} catch (IOException e) {
		}
	}

	public void browse(String path, ItemsCallback handlers) {
		ArrayList<CollectionItem> items = offlineCache.browse(path);
		if (items == null) {
			handlers.onError();
		} else {
			handlers.onSuccess(items);
		}
	}

	public void flatten(String path, ItemsCallback handlers) {
		ArrayList<CollectionItem> items = offlineCache.flatten(path);
		if (items == null) {
			handlers.onError();
		} else {
			handlers.onSuccess(items);
		}
	}
}
