package agersant.polaris.api.local;

import android.content.Context;
import android.content.Intent;
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
import agersant.polaris.PolarisApplication;

/**
 * Created by agersant on 12/25/2016.
 */

public class OfflineCache {

	public static final String AUDIO_CACHED = "AUDIO_CACHED";
	private static final int VERSION = 1;
	private static final int BUFFER_SIZE = 1024 * 64;
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

	private static void write(Bitmap image, OutputStream storage) throws IOException {
		storage.write(OfflineCache.VERSION);
	}

	public void put(CollectionItem item, FileInputStream audio, Bitmap image) {
		String path = item.getPath();

		try (FileOutputStream itemOut = new FileOutputStream(getCacheFile(path, CacheDataType.ITEM, true))) {
			write(item, itemOut);
		} catch (IOException e) {
			System.out.println("Error while caching item for local use: " + e);
		}

		if (audio != null) {
			try (FileOutputStream itemOut = new FileOutputStream(getCacheFile(path, CacheDataType.AUDIO, true))) {
				write(audio, itemOut);
				broadcast(AUDIO_CACHED);
			} catch (IOException e) {
				System.out.println("Error while caching audio for local use: " + e);
			}
		}

		if (image != null) {
			try (FileOutputStream itemOut = new FileOutputStream(getCacheFile(path, CacheDataType.ARTWORK, true))) {
				write(image, itemOut);
			} catch (IOException e) {
				System.out.println("Error while caching artwork for local use: " + e);
			}
		}

		System.out.println("Saved to offline cache: " + path);
	}

	private File getCacheFile(String virtualPath, CacheDataType type, boolean create) throws IOException {
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
		if (create) {
			if (!file.exists()) {
				file.getParentFile().mkdirs();
				file.createNewFile();
			}
		}
		return file;
	}

	public boolean hasAudio(String path) {
		try {
			File file = getCacheFile(path, CacheDataType.AUDIO, false);
			return file.exists();
		} catch (IOException e) {
			return false;
		}
	}

	MediaDataSource getAudio(String path) {
		if (!hasAudio(path)) {
			return null;
		}
		try {
			File source = getCacheFile(path, CacheDataType.AUDIO, false);
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

	private void broadcast(String event) {
		PolarisApplication application = PolarisApplication.getInstance();
		Intent intent = new Intent();
		intent.setAction(event);
		application.sendBroadcast(intent);
	}

	private enum CacheDataType {
		ITEM,
		AUDIO,
		ARTWORK,
	}

}
