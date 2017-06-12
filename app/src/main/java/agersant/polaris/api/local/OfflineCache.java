package agersant.polaris.api.local;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.preference.PreferenceManager;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisService;
import agersant.polaris.R;

/**
 * Created by agersant on 12/25/2016.
 */

public class OfflineCache {

	public static final String AUDIO_CACHED = "AUDIO_CACHED";
	public static final String AUDIO_REMOVED_FROM_CACHE = "AUDIO_REMOVED_FROM_CACHE";
	private static final String ITEM_FILENAME = "__polaris__item";
	private static final String AUDIO_FILENAME = "__polaris__audio";
	private static final String META_FILENAME = "__polaris__meta";
	private static final int FIRST_VERSION = 1;
	private static final int VERSION = 2;
	private static final int BUFFER_SIZE = 1024 * 64;
	private SharedPreferences preferences;
	private File root;
	private PolarisService service;

	public OfflineCache(PolarisService service) {
		this.service = service;
		preferences = PreferenceManager.getDefaultSharedPreferences(service);

		for (int i = FIRST_VERSION; i <= VERSION; i++) {
			root = new File(service.getExternalCacheDir(), "collection");
			root = new File(root, "v" + i);
			if (i != VERSION) {
				deleteDirectory(root);
			}
		}
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

	private void write(ItemCacheMetadata metadata, OutputStream storage) throws IOException {
		ObjectOutputStream objOut = new ObjectOutputStream(storage);
		objOut.writeObject(metadata);
		objOut.close();
	}

	private void listDeletionCandidates(File path, ArrayList<DeletionCandidate> candidates) {
		assert (path.isDirectory());
		File[] files = path.listFiles();
		for (File child : files) {
			File audio = new File(child, AUDIO_FILENAME);
			if (audio.exists()) {

				ItemCacheMetadata metadata = new ItemCacheMetadata();
				metadata.lastUse = new Date(0L);

				File meta = new File(child, META_FILENAME);
				if (meta.exists()) {
					try {
						metadata = readMetadata(meta);
					} catch (IOException e) {
						System.out.println("Error reading file metadata for " + child + " " + e);
					}
				}

				CollectionItem item = null;
				try {
					item = readItem(child);
				} catch (Exception e) {
					System.out.println("Error reading collection item for " + child + " " + e);
				}

				DeletionCandidate candidate = new DeletionCandidate(child, metadata, item);
				candidates.add(candidate);
			} else if (child.isDirectory()) {
				listDeletionCandidates(child, candidates);
			}
		}
	}

	private long getCacheSize(File file) {
		long size = 0;
		assert (file.isDirectory());
		File[] files = file.listFiles();
		if (files != null) {
			for (File child : files) {
				size += child.length();
				if (child.isDirectory()) {
					size += getCacheSize(child);
				}
			}
		}
		return size;
	}

	private long getCacheCapacity() {
		Resources resources = service.getResources();
		String cacheSizeKey = resources.getString(R.string.pref_key_offline_cache_size);
		String cacheSizeString = preferences.getString(cacheSizeKey, "0");
		return Long.parseLong(cacheSizeString) * 1024 * 1024;
	}

	private boolean removeOldAudio(File path, CollectionItem newItem, long bytesToSave) {
		ArrayList<DeletionCandidate> candidates = new ArrayList<>();
		listDeletionCandidates(path, candidates);

		Collections.sort(candidates, new Comparator<DeletionCandidate>() {
			@Override
			public int compare(DeletionCandidate a, DeletionCandidate b) {
				if (a.item == null && b.item != null) {
					return -1;
				}
				if (b.item == null && a.item != null) {
					return 1;
				}
				if (b.item != null && a.item != null) {
					return -service.comparePriorities(a.item, b.item);
				}
				return (int) (a.metadata.lastUse.getTime() - b.metadata.lastUse.getTime());
			}
		});

		long cleared = 0;
		for (DeletionCandidate candidate : candidates) {
			try {
				if (candidate.item != null) {
					if (service.comparePriorities(candidate.item, newItem) <= 0) {
						continue;
					}
				}
			} catch (Exception e) {
			}

			File audio = new File(candidate.cachePath, AUDIO_FILENAME);
			if (audio.exists()) {
				long size = audio.length();
				if (audio.delete()) {
					System.out.println("Deleting " + audio);
					cleared += size;
				}
				if (cleared >= bytesToSave) {
					break;
				}
			}
		}

		if (cleared > 0) {
			broadcast(AUDIO_REMOVED_FROM_CACHE);
		}
		return cleared >= bytesToSave;
	}

	public synchronized boolean makeSpace(CollectionItem item) {
		long cacheSize = getCacheSize(root);
		long cacheCapacity = getCacheCapacity();
		long overflow = cacheSize - cacheCapacity;
		boolean success = true;
		if (overflow > 0) {
			success = removeOldAudio(root, item, overflow);
			removeEmptyDirectories(root);
		}
		return success;
	}

	private void deleteDirectory(File path) {
		assert (path.isDirectory());
		File[] files = path.listFiles();
		if (files == null) {
			return;
		}
		for (File child : files) {
			if (child.isDirectory()) {
				deleteDirectory(child);
			} else {
				child.delete();
			}
		}
		path.delete();
	}

	private void removeEmptyDirectories(File path) {
		// TODO: Catastrophic complexity
		assert (path.isDirectory());
		File[] files = path.listFiles();
		for (File child : files) {
			if (child.isDirectory()) {
				if (!containsAudio(child)) {
					System.out.println("Deleting " + child);
					deleteDirectory(child);
				} else {
					removeEmptyDirectories(child);
				}
			}
		}
	}

	public synchronized void putAudio(CollectionItem item, FileInputStream audio) {

		makeSpace(item);

		String path = item.getPath();

		try (FileOutputStream itemOut = new FileOutputStream(getCacheFile(path, CacheDataType.ITEM, true))) {
			write(item, itemOut);
		} catch (IOException e) {
			System.out.println("Error while caching item for local use: " + e);
			return;
		}

		if (audio != null) {
			try (FileOutputStream itemOut = new FileOutputStream(getCacheFile(path, CacheDataType.AUDIO, true))) {
				write(audio, itemOut);
				broadcast(AUDIO_CACHED);
			} catch (IOException e) {
				System.out.println("Error while caching audio for local use: " + e);
				return;
			}
		}

		if (!hasMetadata(path)) {
			saveMetadata(path, new ItemCacheMetadata());
		}

		System.out.println("Saved audio to offline cache: " + path);
	}

	public synchronized void putImage(CollectionItem item, Bitmap image) {
		String path = item.getPath();

		try (FileOutputStream itemOut = new FileOutputStream(getCacheFile(path, CacheDataType.ITEM, true))) {
			write(item, itemOut);
		} catch (IOException e) {
			System.out.println("Error while caching item for local use: " + e);
		}

		if (image != null) {
			String artworkPath = item.getArtwork();
			assert (artworkPath != null);
			try (FileOutputStream itemOut = new FileOutputStream(getCacheFile(artworkPath, CacheDataType.ARTWORK, true))) {
				write(image, itemOut);
			} catch (IOException e) {
				System.out.println("Error while caching artwork for local use: " + e);
			}
		}

		System.out.println("Saved image to offline cache: " + path);
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
				break;
			case META:
			default:
				file = new File(file, META_FILENAME);
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

	boolean hasImage(String virtualPath) {
		try {
			File file = getCacheFile(virtualPath, CacheDataType.ARTWORK, false);
			return file.exists();
		} catch (IOException e) {
			return false;
		}
	}

	Uri getAudio(String virtualPath) throws IOException {
		if (!hasAudio(virtualPath)) {
			throw new FileNotFoundException();
		}
		if (hasMetadata(virtualPath)) {
			ItemCacheMetadata metadata = getMetadata(virtualPath);
			metadata.lastUse = new Date();
			saveMetadata(virtualPath, metadata);
		}
		return Uri.fromFile(getCacheFile(virtualPath, CacheDataType.AUDIO, false));
	}

	Bitmap getImage(String virtualPath) throws IOException {
		if (!hasImage(virtualPath)) {
			throw new FileNotFoundException();
		}
		File file = getCacheFile(virtualPath, CacheDataType.ARTWORK, false);
		FileInputStream fileInputStream = new FileInputStream(file);
		return BitmapFactory.decodeFileDescriptor(fileInputStream.getFD());
	}

	private void saveMetadata(String virtualPath, ItemCacheMetadata metadata) {
		try (FileOutputStream metaOut = new FileOutputStream(getCacheFile(virtualPath, CacheDataType.META, true))) {
			write(metadata, metaOut);
		} catch (IOException e) {
			System.out.println("Error while caching metadata for local use: " + e);
		}
	}

	private boolean hasMetadata(String virtualPath) {
		try {
			File file = getCacheFile(virtualPath, CacheDataType.META, false);
			return file.exists();
		} catch (IOException e) {
			return false;
		}
	}

	private ItemCacheMetadata readMetadata(File file) throws IOException {
		try (FileInputStream fileInputStream = new FileInputStream(file);
			 ObjectInputStream objectInputStream = new ObjectInputStream(fileInputStream);
		) {
			return (ItemCacheMetadata) objectInputStream.readObject();
		} catch (ClassNotFoundException e) {
			throw new FileNotFoundException();
		}
	}

	private ItemCacheMetadata getMetadata(String virtualPath) throws IOException {
		if (!hasMetadata(virtualPath)) {
			throw new FileNotFoundException();
		}
		File file = getCacheFile(virtualPath, CacheDataType.META, false);
		return readMetadata(file);
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
				if (!file.isDirectory()) {
					continue;
				}
				if (isInternalFile(file)) {
					continue;
				}
				CollectionItem item = readItem(file);
				if (item.isDirectory()) {
					if (!containsAudio(file)) {
						continue;
					}
				}
				out.add(item);
			} catch (IOException | ClassNotFoundException e) {
				System.out.println("Error while reading offline cache: " + e);
				continue;
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
		boolean isMeta = name.equals(META_FILENAME);
		return isItem || isAudio || isMeta;
	}

	private boolean containsAudio(File file) {
		if (!file.isDirectory()) {
			return file.getName().equals(AUDIO_FILENAME);
		}
		File[] files = file.listFiles();
		for (File child : files) {
			if (containsAudio(child)) {
				return true;
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
					ArrayList<CollectionItem> content = flattenDir(file);
					if (content != null) {
						out.addAll(content);
					}
				} else if (hasAudio(item.getPath()))  {
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
		META,
	}

	private class DeletionCandidate {
		File cachePath;
		ItemCacheMetadata metadata;
		CollectionItem item;

		DeletionCandidate(File cachePath, ItemCacheMetadata metadata, CollectionItem item) {
			this.cachePath = cachePath;
			this.metadata = metadata;
			this.item = item;
		}
	}

}
