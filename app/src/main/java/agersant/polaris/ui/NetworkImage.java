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
import agersant.polaris.api.ServerAPI;
import agersant.polaris.cache.ImageCache;

public class NetworkImage extends AsyncTask<Void, Void, Bitmap> {

	private final WeakReference<ImageView> imageViewReference;

	private String url;
	private String authCookie;

	private NetworkImage(String url, ImageView imageView, String authCookie) {
		this.url = url;
		this.authCookie = authCookie;
		imageViewReference = new WeakReference<>(imageView);
	}

	public static void load(String url, ImageView imageView) {
		if (NetworkImage.cancelPotentialWork(url, imageView)) {
			ImageCache cache = ImageCache.getInstance();
			Bitmap cacheEntry = cache.get(url);
			if (cacheEntry != null) {
				imageView.setImageBitmap(cacheEntry);
				return;
			}

			PolarisApplication polarisApplication = PolarisApplication.getInstance();
			Resources resources = polarisApplication.getResources();
			ServerAPI serverAPI = ServerAPI.getInstance(polarisApplication);
			String authCookie = serverAPI.getAuthCookie();

			NetworkImage task = new NetworkImage(url, imageView, authCookie);
			NetworkImage.AsyncDrawable asyncDrawable = new NetworkImage.AsyncDrawable(resources, null, task);
			imageView.setImageDrawable(asyncDrawable);
			task.execute();
		}
	}

	private static NetworkImage getTask(ImageView imageView) {
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
		NetworkImage task = getTask(imageView);
		if (task != null) {
			if (task.url.equals(newURL)) {
				return false;
			} else {
				task.cancel(true);
			}
		}
		return true;
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
			NetworkImage task = getTask(imageView);
			if (imageView != null && task == this) {
				imageView.setImageBitmap(bitmap);
			}
		}
	}

	private static class AsyncDrawable extends BitmapDrawable {
		private WeakReference<NetworkImage> task;

		AsyncDrawable(Resources res, Bitmap bitmap, NetworkImage task) {
			super(res, bitmap);
			this.task = new WeakReference<>(task);
		}

		NetworkImage getTask() {
			return task.get();
		}
	}
}
