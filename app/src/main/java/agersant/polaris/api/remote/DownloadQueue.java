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

	private DownloadQueueWorkItem flip;
	private DownloadQueueWorkItem flop;

	private DownloadQueue(Context context) {
		{
			File tempFile = new File(context.getExternalCacheDir(), "streamA.tmp");
			flip = new DownloadQueueWorkItem(tempFile);
		}
		{
			File tempFile = new File(context.getExternalCacheDir(), "streamB.tmp");
			flop = new DownloadQueueWorkItem(tempFile);
		}
	}

	public static void init(Context context) {
		instance = new DownloadQueue(context);
	}

	public static DownloadQueue getInstance() {
		return instance;
	}

	MediaDataSource getAudio(CollectionItem item) throws IOException {
		if (flip.isHandling(item)) {
			return flip.getMediaDataSource();
		}
		if (flop.isHandling(item)) {
			return flop.getMediaDataSource();
		}
		if (flip.isIdle()) {
			flip.beginDownload(item);
			return flip.getMediaDataSource();
		}
		if (flop.isIdle()) {
			flop.beginDownload(item);
			return flop.getMediaDataSource();
		}
		return null;
	}

}
