package agersant.polaris.api.remote;

import android.content.Context;
import android.media.MediaDataSource;

import java.io.File;
import java.io.IOException;
import java.util.Timer;
import java.util.TimerTask;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.api.API;
import agersant.polaris.api.local.OfflineCache;

/**
 * Created by agersant on 12/25/2016.
 */

public class DownloadQueue {

	private static DownloadQueue instance;

	private Timer timer;
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

		timer = new Timer();
		timer.scheduleAtFixedRate(new TimerTask() {
			@Override
			public void run() {
				downloadNext();
			}
		}, 0, 500);
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

	public boolean isWorkingOn(CollectionItem item) {
		return flip.isHandling(item) || flop.isHandling(item);
	}

	private void downloadNext() {

		if (API.getInstance().isOffline()) {
			return;
		}

		DownloadQueueWorkItem worker = null;
		if (flip.isIdle()) {
			worker = flip;
		} else if (flop.isIdle()) {
			worker = flop;
		}

		if (worker == null) {
			return;
		}

		PlaybackQueue queue = PlaybackQueue.getInstance();
		CollectionItem nextItem = queue.getNextItemToDownload();
		if (nextItem != null) {

			OfflineCache offlineCache = OfflineCache.getInstance();
			if (!offlineCache.makeSpace(nextItem)) {
				return;
			}

			try {
				worker.beginDownload(nextItem);
			} catch (IOException e) {
				System.out.println("Error while downloading item ahead of time: " + e);
			}
		}
	}

}
