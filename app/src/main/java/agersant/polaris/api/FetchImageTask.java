package agersant.polaris.api;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.os.AsyncTask;

import junit.framework.Assert;

import java.io.BufferedInputStream;
import java.io.InputStream;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.api.local.ImageCache;
import agersant.polaris.api.local.LocalAPI;
import okhttp3.ResponseBody;

public class FetchImageTask extends AsyncTask<Void, Void, Bitmap> {

	private final CollectionItem item;
	private final PolarisService service;
	private final Callback callback;

	private FetchImageTask(PolarisService service, CollectionItem item, Callback callback) {
		this.service = service;
		this.item = item;
		this.callback = callback;
	}

	static void load(PolarisService service, CollectionItem item, Callback callback) {
		FetchImageTask task = new FetchImageTask(service, item, callback);
		task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
	}

	@Override
	protected Bitmap doInBackground(Void... params) {
		String artworkPath = item.getArtwork();
		Assert.assertNotNull(artworkPath);

		Bitmap bitmap = null;
		boolean fromDiskCache = false;

		LocalAPI localAPI = service.getLocalAPI();
		if (localAPI.hasImage(item)) {
			bitmap = localAPI.getImage(item);
			fromDiskCache = bitmap != null;
		}
		if (bitmap == null) {
			if (!service.isOffline()) {
				try {
					ResponseBody responseBody = service.getServerAPI().serve(item.getArtwork());
					InputStream stream = new BufferedInputStream(responseBody.byteStream());
					bitmap = BitmapFactory.decodeStream(stream);
				} catch (Exception e) {
					System.out.println("Error while downloading image: " + e.toString());
				}
			}
		}

		if (bitmap != null) {
			ImageCache cache = ImageCache.getInstance();
			cache.put(item.getArtwork(), bitmap);
			if (!fromDiskCache) {
				service.saveImage(item, bitmap);
			}
		}

		return bitmap;
	}

	@Override
	protected void onPostExecute(Bitmap bitmap) {
		if (bitmap != null) {
			callback.onSuccess(bitmap);
		}
	}

	public interface Callback {
		void onSuccess(Bitmap bitmap);
	}

	static class AsyncDrawable extends BitmapDrawable {
		private final CollectionItem item;

		AsyncDrawable(Resources res, CollectionItem item) {
			super(res, (Bitmap) null);
			this.item = item;
		}

		public CollectionItem getItem() {
			return item;
		}
	}
}
