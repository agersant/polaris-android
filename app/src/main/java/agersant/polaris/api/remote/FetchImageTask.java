package agersant.polaris.api.remote;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.AsyncTask;
import android.widget.ImageView;

import java.io.BufferedInputStream;
import java.io.InputStream;
import java.lang.ref.WeakReference;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisService;
import agersant.polaris.api.local.ImageCache;
import okhttp3.ResponseBody;

class FetchImageTask extends AsyncTask<Void, Void, Bitmap> {

	private final WeakReference<ImageView> imageViewReference;

	private CollectionItem item;
	private String path;
	private PolarisService service;

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
		Bitmap bitmap = null;
		try {
			ResponseBody responseBody = service.getServerAPI().serve(path);
			InputStream stream = new BufferedInputStream(responseBody.byteStream());
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
			cache.put(path, bitmap);

			service.saveImage(item, bitmap);

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
