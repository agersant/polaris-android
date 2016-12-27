package agersant.polaris.api.local;

import android.content.Context;
import android.graphics.Bitmap;
import android.media.MediaDataSource;

import com.android.volley.Response;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;

/**
 * Created by agersant on 12/25/2016.
 */

public class OfflineCache {

	static final int VERSION = 1;
	static final int BUFFER_SIZE = 1024 * 64;
	private static OfflineCache instance;
	private File root;

	private OfflineCache(Context context) {
		root = new File(context.getExternalCacheDir(), "collection_cache");
	}

	public static void init(Context context) {
		if (instance == null) {
			instance = new OfflineCache(context);
		}
	}

	public static OfflineCache getInstance() {
		return instance;
	}

	private static void write(CollectionItem item, OutputStream storage) throws IOException {
		storage.write(OfflineCache.VERSION);
		ObjectOutputStream objOut = new ObjectOutputStream(storage);
		objOut.writeObject(item);
		objOut.close();
	}

	private static void write(FileInputStream audio, OutputStream storage) throws IOException {
		storage.write(OfflineCache.VERSION);
		byte[] buffer = new byte[BUFFER_SIZE];
		int read;
		while ((read = audio.read(buffer)) > 0) {
			storage.write(buffer, 0, read);
		}
	}

	private static void write(Bitmap image, OutputStream storage) {
		// TODO
	}

	public void put(CollectionItem item, FileInputStream audio, Bitmap image) {
		String path = item.getPath();
		try (
				FileOutputStream itemOut = new FileOutputStream(getCacheFile(path, CacheDataType.ITEM));
				FileOutputStream audioOut = new FileOutputStream(getCacheFile(path, CacheDataType.AUDIO));
				FileOutputStream artworkOut = new FileOutputStream(getCacheFile(path, CacheDataType.ARTWORK));
		) {
			write(item, itemOut);
			if (audio != null) {
				write(audio, audioOut);
			}
			if (image != null) {
				write(image, artworkOut);
			}
			System.out.println("Saved to offline cache: " + path);
		} catch (IOException e) {
			System.out.println("Error while caching for local use: " + e);
		}
	}

	private File getCacheFile(String virtualPath, CacheDataType type) throws IOException {
		String path = virtualPath.replace("\\", File.separator);
		File file = new File(root, path);
		if (file.isDirectory()) {
			file = new File(file, "__polaris__dir__");
		}
		switch (type) {
			case ITEM:
				file = new File(file, "item");
			case AUDIO:
				file = new File(file, "audio");
			case ARTWORK:
			default:
				file = new File(file, "artwork");
		}
		if (!file.exists()) {
			file.getParentFile().mkdirs();
			file.createNewFile();
		}
		return file;
	}

	MediaDataSource getAudio(String path) {
		try {
			File source = getCacheFile(path, CacheDataType.AUDIO);
			return new LocalMediaDataSource(source);
		} catch (IOException e) {
			return null;
		}
	}

	public void browse(String path, final Response.Listener<ArrayList<CollectionItem>> success, Response.ErrorListener failure) {
		File file = new File(root, path);
		if (!file.exists() || !file.isDirectory()) {
			failure.onErrorResponse(null);
			return;
		}
	}

	private enum CacheDataType {
		ITEM,
		AUDIO,
		ARTWORK,
	}

}
