package agersant.polaris.api;

import android.os.AsyncTask;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

import agersant.polaris.CollectionItem;
import agersant.polaris.cache.OfflineCache;

/**
 * Created by agersant on 12/26/2016.
 */

public class DownloadTask extends AsyncTask<Object, Integer, Integer> {

	private static final int BUFFER_SIZE = 1024 * 64; // 64 kB

	private CollectionItem item;
	private String targetURL;
	private String authCookie;
	private File outFile;
	private boolean reachedEOF;
	private StreamingMediaDataSource dataSource;

	DownloadTask(ServerAPI server, CollectionItem item, File file, StreamingMediaDataSource stream) {
		this.item = item;
		targetURL = server.getMediaURL(item.getPath());
		authCookie = server.getAuthCookie(); // TODO not guaranteed
		outFile = file;
		reachedEOF = false;
		dataSource = stream;
	}

	public String getPath() {
		return item.getPath();
	}

	@Override
	protected Integer doInBackground(Object... params) {

		FileOutputStream outputStream = null;
		InputStream inputStream = null;

		try {

			URL url = new URL(targetURL);
			HttpURLConnection connection = (HttpURLConnection) url.openConnection();
			connection.setRequestProperty("Cookie", authCookie);

			outputStream = new FileOutputStream(outFile);
			inputStream = connection.getInputStream();
			byte[] chunk = new byte[BUFFER_SIZE];
			while (true) {
				int bytesRead = inputStream.read(chunk);
				if (bytesRead > 0) {
					outputStream.write(chunk, 0, bytesRead);
				}
				if (bytesRead == -1) {
					reachedEOF = true;
					break;
				}
				if (isCancelled()) {
					break;
				}
			}

		} catch (IOException e) {
			System.out.println("IO Error during download");
		}

		if (inputStream != null) {
			try {
				inputStream.close();
			} catch (IOException e) {
				System.out.println("IO Error during download input cleanup");
			}
		}

		if (outputStream != null) {
			try {
				outputStream.close();
			} catch (IOException e) {
				System.out.println("IO Error during download output cleanup");
			}
		}

		return 0;
	}

	@Override
	protected void onPostExecute(Integer result) {
		if (!reachedEOF) {
			return;
		}

		OfflineCache cache = OfflineCache.getInstance();

		try (FileInputStream audioStreamFile = new FileInputStream(outFile)) {
			cache.put(item, audioStreamFile, null);
		} catch (IOException e) {
			System.out.println("Error while storing item to offline cache: " + e);
		}
		dataSource.markAsComplete();
	}

}
