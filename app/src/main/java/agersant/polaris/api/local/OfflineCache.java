package agersant.polaris.api.local;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaDataSource;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
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
	private static final String ITEM_FILENAME = "__polaris__item";
	private static final String AUDIO_FILENAME = "__polaris__audio";
	private static final String IMAGE_FILENAME = "__polaris__image";
	private static final int VERSION = 1;
	private static final int BUFFER_SIZE = 1024 * 64;
	private static OfflineCache instance;
	private File root;

	private OfflineCache(Context context) {
		root = new File(context.getExternalCacheDir(), "collection");
		root = new File(root, "v" + VERSION);
	}

	public static void init(Context context) {
		if (instance == null) {
			instance = new OfflineCache(context);
		}
	}

	public static OfflineCache getInstance() {
		return instance;
	}

	private void write(CollectionItem item, OutputStream storage) throws IOException {
		ObjectOutputStream objOut = new ObjectOutputStream(storage);
		objOut.writeObject(item);
		objOut.close();
	}

	private void write(FileInputStream audio, OutputStream storage) throws IOException {
		byte[] buffer = new byte[BUFFER_SIZE];
		int read;
		while ((read = audio.read(buffer)) > 0) {
			storage.write(buffer, 0, read);
		}
	}

	private void write(Bitmap image, OutputStream storage) throws IOException {
		image.compress(Bitmap.CompressFormat.PNG, 100, storage);
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
			String artworkPath = item.getArtwork();
			assert(artworkPath != null);
			try (FileOutputStream itemOut = new FileOutputStream(getCacheFile(artworkPath, CacheDataType.ARTWORK, true))) {
				write(image, itemOut);
			} catch (IOException e) {
				System.out.println("Error while caching artwork for local use: " + e);
			}
		}

		System.out.println("Saved to offline cache: " + path);
	}

	private File getCacheDir(String virtualPath) {
		String path = virtualPath.replace("\\", File.separator);
		return new File(root, path);
	}

	private File getCacheFile(String virtualPath, CacheDataType type, boolean create) throws IOException {
		File file = getCacheDir(virtualPath);
		switch (type) {
			case ITEM:
				file = new File(file, ITEM_FILENAME);
				break;
			case AUDIO:
				file = new File(file, AUDIO_FILENAME);
				break;
			case ARTWORK:
			default:
				file = new File(file, IMAGE_FILENAME);
				break;
		}
		if (create) {
			if (!file.exists()) {
				File parent = file.getParentFile();
				parent.mkdirs();
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

	boolean hasImage(String path) {
		try {
			File file = getCacheFile(path, CacheDataType.ARTWORK, false);
			return file.exists();
		} catch (IOException e) {
			return false;
		}
	}

	MediaDataSource getAudio(String path) throws IOException {
		if (!hasAudio(path)) {
			throw new FileNotFoundException();
		}
		File source = getCacheFile(path, CacheDataType.AUDIO, false);
		return new LocalMediaDataSource(source);
	}

	Bitmap getImage(String path) throws IOException {
		if (!hasImage(path)) {
			throw new FileNotFoundException();
		}
		File file = getCacheFile(path, CacheDataType.ARTWORK, false);
		FileInputStream fileInputStream = new FileInputStream(file);
		return BitmapFactory.decodeFileDescriptor(fileInputStream.getFD());
	}

	public ArrayList<CollectionItem> browse(String path) {
		ArrayList<CollectionItem> out = new ArrayList<>();
		File dir = getCacheDir(path);
		File[] files = dir.listFiles();
		if (files == null) {
			return out;
		}

		for (File file : files) {
			try {
				if (isInternalFile(file)) {
					continue;
				}
				CollectionItem item = readItem(file);
				out.add(item);
			} catch (IOException | ClassNotFoundException e) {
				System.out.println("Error while reading offline cache: " + e);
				return null;
			}
		}

		return out;
	}

	ArrayList<CollectionItem> flatten(String path) {
		File dir = getCacheDir(path);
		return flattenDir(dir);
	}

	private boolean isInternalFile(File file) {
		String name = file.getName();
		boolean isItem = name.equals(ITEM_FILENAME);
		boolean isAudio = name.equals(AUDIO_FILENAME);
		boolean isImage = name.equals(IMAGE_FILENAME);
		if (isItem || isAudio || isImage) {
			return true;
		}
		if (file.isDirectory()) {
			File[] files = file.listFiles();
			if (files.length == 1) {
				if (files[0].getName().equals(IMAGE_FILENAME)) {
					return true;
				}
			}
		}
		return false;
	}

	private ArrayList<CollectionItem> flattenDir(File source) {
		assert (source.isDirectory());
		ArrayList<CollectionItem> out = new ArrayList<>();
		File[] files = source.listFiles();
		if (files == null) {
			return out;
		}

		for (File file : files) {
			try {
				if (isInternalFile(file)) {
					continue;
				}
				CollectionItem item = readItem(file);
				if (item.isDirectory()) {
					out.addAll(flattenDir(file));
				} else {
					out.add(item);
				}
			} catch (IOException | ClassNotFoundException e) {
				System.out.println("Error while reading offline cache: " + e);
				return null;
			}
		}
		return out;
	}

	private CollectionItem readItem(File dir) throws IOException, ClassNotFoundException {
		File itemFile = new File(dir, ITEM_FILENAME);
		if (!itemFile.exists()) {
			String path = root.toURI().relativize(dir.toURI()).getPath();
			return CollectionItem.directory(path);
		}
		try (FileInputStream fileInputStream = new FileInputStream(itemFile);
			 ObjectInputStream objectInputStream = new ObjectInputStream(fileInputStream);
		) {
			return (CollectionItem) objectInputStream.readObject();
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
