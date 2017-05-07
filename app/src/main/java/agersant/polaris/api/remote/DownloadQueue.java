package agersant.polaris.api.remote;

import android.content.Context;
import android.media.MediaDataSource;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
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
	private ArrayList<DownloadQueueWorkItem> workers;

	private DownloadQueue(Context context) {
		workers = new ArrayList<>();
		for (int i = 0; i < 2; i++)
		{
			File file = new File(context.getExternalCacheDir(), "stream" + i + ".tmp");
			DownloadQueueWorkItem worker = new DownloadQueueWorkItem(file);
			workers.add(worker);
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

	synchronized MediaDataSource getAudio(CollectionItem item) throws IOException {
		DownloadQueueWorkItem existingWorker = findActiveWorker(item);
		if (existingWorker != null) {
			return existingWorker.getMediaDataSource();
		}

		DownloadQueueWorkItem newWorker = findIdleWorker();
		if (newWorker == null) {
			newWorker = findInterruptibleWorker();
			assert newWorker != null;
		}

		newWorker.beginDownload(item);
		return newWorker.getMediaDataSource();
	}

	private DownloadQueueWorkItem findActiveWorker(CollectionItem item) {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.isHandling(item)) {
				return worker;
			}
		}
		return null;
	}

	private DownloadQueueWorkItem findIdleWorker() {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.isIdle()) {
				return worker;
			}
		}
		return null;
	}

	private DownloadQueueWorkItem findInterruptibleWorker() {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.isInterruptible()) {
				return worker;
			}
		}
		return null;
	}

	public boolean isWorkingOn(CollectionItem item) {
		return findActiveWorker(item) != null;
	}

	private synchronized void downloadNext() {

		if (API.getInstance().isOffline()) {
			return;
		}

		DownloadQueueWorkItem worker = findIdleWorker();
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
