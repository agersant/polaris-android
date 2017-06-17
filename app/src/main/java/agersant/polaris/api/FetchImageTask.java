package agersant.polaris.api;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.AsyncTask;
import android.widget.ImageView;

import junit.framework.Assert;

import java.io.BufferedInputStream;
import java.io.InputStream;
import java.lang.ref.WeakReference;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisService;
import agersant.polaris.api.local.ImageCache;
import agersant.polaris.api.local.LocalAPI;
import okhttp3.ResponseBody;

class FetchImageTask extends AsyncTask<Void, Void, Bitmap> {

	private final WeakReference<ImageView> imageViewReference;

	private final CollectionItem item;
	private final String path;
	private final PolarisService service;

	private FetchImageTask(PolarisService service, CollectionItem item, ImageView imageView) {
		this.service = service;
		this.item = item;
		this.path = item.getArtwork();
		imageViewReference = new WeakReference<>(imageView);
	}

	static void load(PolarisService service, CollectionItem item, ImageView imageView) {
		if (FetchImageTask.cancelPotentialWork(item, imageView)) {
			PolarisApplication polarisApplication = PolarisApplication.getInstance();
			Resources resources = polarisApplication.getResources();

			FetchImageTask task = new FetchImageTask(service, item, imageView);
			FetchImageTask.AsyncDrawable asyncDrawable = new FetchImageTask.AsyncDrawable(resources, task);
			imageView.setImageDrawable(asyncDrawable);
			task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
		}
	}

	private static FetchImageTask getTask(ImageView imageView) {
		if (imageView != null) {
			Drawable drawable = imageView.getDrawable();
			if (drawable instanceof AsyncDrawable) {
				final AsyncDrawable asyncDrawable = (AsyncDrawable) drawable;
				return asyncDrawable.getTask();
			}
		}
		return null;
	}

	private static boolean cancelPotentialWork(CollectionItem newItem, ImageView imageView) {
		FetchImageTask task = getTask(imageView);
		if (task != null) {
			if (task.path.equals(newItem.getPath())) {
				return false;
			} else {
				task.cancel(true);
			}
		}
		return true;
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
					ResponseBody responseBody = service.getServerAPI().serve(path);
					InputStream stream = new BufferedInputStream(responseBody.byteStream());
					bitmap = BitmapFactory.decodeStream(stream);
				} catch (Exception e) {
					System.out.println("Error while downloading image: " + e.toString());
				}
			}
		}

		if (bitmap != null) {
			ImageCache cache = ImageCache.getInstance();
			cache.put(path, bitmap);
			if (!fromDiskCache) {
				service.saveImage(item, bitmap);
			}
		}

		return bitmap;
	}

	@Override
	protected void onPostExecute(Bitmap bitmap) {
		if (isCancelled()) {
			bitmap = null;
		}
		if (bitmap != null) {
			ImageView imageView = imageViewReference.get();
			FetchImageTask task = getTask(imageView);
			if (imageView != null && task == this) {
				imageView.setImageBitmap(bitmap);
			}
		}
	}

	private static class AsyncDrawable extends BitmapDrawable {
		private final WeakReference<FetchImageTask> task;

		AsyncDrawable(Resources res, FetchImageTask task) {
			super(res, (Bitmap) null);
			this.task = new WeakReference<>(task);
		}

		FetchImageTask getTask() {
			return task.get();
		}
	}
}
