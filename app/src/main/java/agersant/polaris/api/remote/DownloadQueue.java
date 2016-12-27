package agersant.polaris.api.remote;

import android.content.Context;
import android.media.MediaDataSource;

import java.io.File;
import java.io.IOException;

import agersant.polaris.CollectionItem;

/**
 * Created by agersant on 12/25/2016.
 */

public class DownloadQueue {

	private static DownloadQueue instance;
	private ServerAPI server;
	private File tempFile;

	private DownloadTask job;
	private StreamingMediaDataSource mediaDataSource;

	private DownloadQueue(Context context, ServerAPI server) {
		this.server = server;
		this.tempFile = new File(context.getExternalCacheDir(), "stream.tmp");
	}

	public static void init(Context context, ServerAPI server) {
		instance = new DownloadQueue(context, server);
	}

	public static DownloadQueue getInstance() {
		return instance;
	}

	MediaDataSource getAudio(CollectionItem item) throws IOException {
		beginDownload(item);
		return mediaDataSource;
	}

	private void beginDownload(CollectionItem item) throws IOException {
		String path = item.getPath();
		if (job != null) {
			String currentJobPath = job.getPath();
			if (currentJobPath.equals(path)) {
				return;
			}
			job.cancel(false);
		}

		if (mediaDataSource != null) {
			mediaDataSource.close();
			mediaDataSource = null;
		}

		if (tempFile.exists()) {
			if (!tempFile.delete()) {
				System.out.println("Could not delete streaming file");
			}
		}

		if (!tempFile.createNewFile()) {
			System.out.println("Could not create streaming file");
		}

		mediaDataSource = new StreamingMediaDataSource(tempFile);
		job = new DownloadTask(server, item, tempFile, mediaDataSource);

		job.execute();
	}

}
