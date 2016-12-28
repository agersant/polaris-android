package agersant.polaris.ui;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.AsyncTask;
import android.widget.ImageView;

import java.io.InputStream;
import java.lang.ref.WeakReference;
import java.net.URLConnection;

import agersant.polaris.PolarisApplication;
import agersant.polaris.api.local.ImageCache;
import agersant.polaris.api.remote.ServerAPI;

public class FetchImageTask extends AsyncTask<Void, Void, Bitmap> {

	private final WeakReference<ImageView> imageViewReference;

	private String url;
	private String authCookie;

	private FetchImageTask(String url, ImageView imageView, String authCookie) {
		this.url = url;
		this.authCookie = authCookie;
		imageViewReference = new WeakReference<>(imageView);
	}

	public static void load(String url, ImageView imageView) {
		if (FetchImageTask.cancelPotentialWork(url, imageView)) {
			if (FetchImageTask.loadFromCache(url, imageView)) {
				return;
			}

			PolarisApplication polarisApplication = PolarisApplication.getInstance();
			Resources resources = polarisApplication.getResources();
			ServerAPI serverAPI = ServerAPI.getInstance();
			String authCookie = serverAPI.getAuthCookie();

			FetchImageTask task = new FetchImageTask(url, imageView, authCookie);
			FetchImageTask.AsyncDrawable asyncDrawable = new FetchImageTask.AsyncDrawable(resources, null, task);
			imageView.setImageDrawable(asyncDrawable);
			task.execute();
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

	private static boolean cancelPotentialWork(String newURL, ImageView imageView) {
		FetchImageTask task = getTask(imageView);
		if (task != null) {
			if (task.url.equals(newURL)) {
				return false;
			} else {
				task.cancel(true);
			}
		}
		return true;
	}

	private static boolean loadFromCache(String url, ImageView imageView) {
		ImageCache cache = ImageCache.getInstance();
		Bitmap cacheEntry = cache.get(url);
		if (cacheEntry != null) {
			imageView.setImageBitmap(cacheEntry);
			return true;
		}
		return false;
	}

	@Override
	protected Bitmap doInBackground(Void... params) {
		Bitmap bitmap = null;
		try {
			URLConnection connection = new java.net.URL(url).openConnection();
			connection.setRequestProperty("Cookie", authCookie);
			InputStream stream = connection.getInputStream();
			bitmap = BitmapFactory.decodeStream(stream);
		} catch (Exception e) {
			System.out.println("Error while downloading image: " + e.toString());
		}
		return bitmap;
	}

	@Override
	protected void onPostExecute(Bitmap bitmap) {
		if (isCancelled()) {
			bitmap = null;
		}
		if (bitmap != null) {
			ImageCache cache = ImageCache.getInstance();
			cache.put(url, bitmap);

			ImageView imageView = imageViewReference.get();
			FetchImageTask task = getTask(imageView);
			if (imageView != null && task == this) {
				imageView.setImageBitmap(bitmap);
			}
		}
	}

	private static class AsyncDrawable extends BitmapDrawable {
		private WeakReference<FetchImageTask> task;

		AsyncDrawable(Resources res, Bitmap bitmap, FetchImageTask task) {
			super(res, bitmap);
			this.task = new WeakReference<>(task);
		}

		FetchImageTask getTask() {
			return task.get();
		}
	}
}
