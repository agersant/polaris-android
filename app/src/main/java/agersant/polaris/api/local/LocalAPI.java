package agersant.polaris.api.local;

import android.graphics.Bitmap;
import android.widget.ImageView;

import com.google.android.exoplayer2.source.MediaSource;

import junit.framework.Assert;

import java.io.IOException;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.IPolarisAPI;
import agersant.polaris.api.ItemsCallback;


public class LocalAPI implements IPolarisAPI {

	private final OfflineCache offlineCache;

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

	public Bitmap getImage(CollectionItem item) {
		String artworkPath = item.getArtwork();
		Assert.assertNotNull(artworkPath);
		try {
			return offlineCache.getImage(artworkPath);
		} catch (IOException e) {
			System.out.println( "Error while retrieving image from local cache: " + artworkPath );
		}
		return null;
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
