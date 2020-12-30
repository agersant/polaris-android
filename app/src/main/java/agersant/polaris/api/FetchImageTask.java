package agersant.polaris.api;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.os.AsyncTask;

import java.io.BufferedInputStream;
import java.io.InputStream;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.local.ImageCache;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.local.OfflineCache;
import agersant.polaris.api.remote.ServerAPI;
import okhttp3.ResponseBody;

public class FetchImageTask extends AsyncTask<Void, Void, Bitmap> {

    private final CollectionItem item;
    private final OfflineCache offlineCache;
    private final API api;
    private final ServerAPI serverAPI;
    private final LocalAPI localAPI;
    private final Callback callback;

    private FetchImageTask(OfflineCache offlineCache, API api, ServerAPI serverAPI, LocalAPI localAPI, CollectionItem item, Callback callback) {
        this.offlineCache = offlineCache;
        this.api = api;
        this.serverAPI = serverAPI;
        this.localAPI = localAPI;
        this.item = item;
        this.callback = callback;
    }

    static void load(OfflineCache offlineCache, API api, ServerAPI serverAPI, LocalAPI localAPI, CollectionItem item, Callback callback) {
        FetchImageTask task = new FetchImageTask(offlineCache, api, serverAPI, localAPI, item, callback);
        task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
    }

    @Override
    protected Bitmap doInBackground(Void... params) {

        Bitmap bitmap = null;
        boolean fromDiskCache = false;

        if (localAPI.hasImage(item)) {
            bitmap = localAPI.getImage(item);
            fromDiskCache = bitmap != null;
        }
        if (bitmap == null) {
            if (!api.isOffline()) {
                try {
                    ResponseBody responseBody = serverAPI.getThumbnail(item.getArtwork());
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
                offlineCache.putImage(item, bitmap);
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
