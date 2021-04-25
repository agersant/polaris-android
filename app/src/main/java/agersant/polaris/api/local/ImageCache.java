package agersant.polaris.api.local;

import android.graphics.Bitmap;

import androidx.collection.LruCache;


public class ImageCache {

    private static ImageCache instance;
    private final LruCache<String, Bitmap> lruCache;

    private ImageCache() {
        final int maxMemory = (int) (Runtime.getRuntime().maxMemory() / 1024);
        final int cacheSize = maxMemory / 8;
        lruCache = new LruCache<String, Bitmap>(cacheSize) {
            @Override
            protected int sizeOf(String key, Bitmap bitmap) {
                return bitmap.getByteCount() / 1024;
            }
        };
    }

    public static ImageCache getInstance() {
        if (instance == null) {
            instance = new ImageCache();
        }
        return instance;
    }

    public Bitmap get(String key) {
        return lruCache.get(key);
    }

    public void put(String key, Bitmap value) {
        lruCache.put(key, value);
    }

}
