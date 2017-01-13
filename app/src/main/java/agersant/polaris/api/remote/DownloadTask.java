package agersant.polaris.api.remote;

import android.os.AsyncTask;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLConnection;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.local.OfflineCache;

/**
 * Created by agersant on 12/26/2016.
 */

class DownloadTask extends AsyncTask<Object, Integer, Integer> {

	private static final int BUFFER_SIZE = 1024 * 64; // 64 kB

	private CollectionItem item;
	private String path;
	private File outFile;
	private boolean reachedEOF;
	private StreamingMediaDataSource dataSource;

	DownloadTask(CollectionItem item, File file, StreamingMediaDataSource stream) {
		this.item = item;
		path = item.getPath();
		outFile = file;
		reachedEOF = false;
		dataSource = stream;
	}

	public String getPath() {
		return item.getPath();
	}

	@Override
	protected Integer doInBackground(Object... params) {

		URLConnection connection;
		try {
			connection = ServerAPI.getInstance().serve(path);
		} catch (Exception e) {
			System.out.println("Error establishing stream connection: " + e);
			return 1;
		}

		int contentLength = connection.getContentLength();
		dataSource.setContentLength(contentLength);

		try (InputStream inputStream = connection.getInputStream();
			 FileOutputStream outputStream = new FileOutputStream(outFile);
		) {
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
			System.out.println("Stream download error: " + e);
			return 1;
		}

		saveForOfflineUse();
		return 0;
	}

	private void saveForOfflineUse() {
		if (reachedEOF) {
			OfflineCache cache = OfflineCache.getInstance();
			try (FileInputStream audioStreamFile = new FileInputStream(outFile)) {
				cache.put(item, audioStreamFile, null);
			} catch (IOException e) {
				System.out.println("Error while storing item to offline cache: " + e);
			}
		}
	}

	@Override
	protected void onPostExecute(Integer result) {
		if (reachedEOF) {
			dataSource.markAsComplete();
		} else {
			dataSource.handleError();
		}
	}

}
