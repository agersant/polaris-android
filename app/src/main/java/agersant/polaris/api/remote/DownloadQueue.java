package agersant.polaris.api.remote;

import android.content.Context;

import com.google.android.exoplayer2.source.MediaSource;

import java.io.File;
import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.PolarisPlayer;
import agersant.polaris.api.API;
import agersant.polaris.api.local.OfflineCache;


public class DownloadQueue {

	public static final String WORKLOAD_CHANGED = "WORKLOAD_CHANGED";

	private final API api;
	private final PlaybackQueue playbackQueue;
	private final PolarisPlayer player;
	private final OfflineCache offlineCache;
	private final ArrayList<DownloadQueueWorkItem> workers;

	// TODO It isn't super clear what thread this runs on and whether downloads continue after closing app
	public DownloadQueue(Context context, API api, PlaybackQueue playbackQueue, PolarisPlayer player, OfflineCache offlineCache, ServerAPI serverAPI) {

		this.api  = api;
		this.playbackQueue  = playbackQueue;
		this.player  = player;
		this.offlineCache  = offlineCache;

		workers = new ArrayList<>();
		for (int i = 0; i < 2; i++) {
			File file = new File(context.getExternalCacheDir(), "stream" + i + ".tmp");
			DownloadQueueWorkItem worker = new DownloadQueueWorkItem(file, serverAPI, offlineCache, player);
			workers.add(worker);
		}
		Timer timer = new Timer();
		timer.scheduleAtFixedRate(new TimerTask() {
			@Override
			public void run() {
				downloadNext();
			}
		}, 1500, 500);
	}

	public synchronized MediaSource getAudio(CollectionItem item) {
		DownloadQueueWorkItem existingWorker = findWorkerWithAudioForItem(item);
		if (existingWorker != null) {
			existingWorker.stopBackgroundDownload();
			return existingWorker.getMediaSource();
		}

		DownloadQueueWorkItem newWorker = findIdleWorker();
		if (newWorker == null) {
			newWorker = findWorkerToInterrupt();
		}

		newWorker.assignItem(item);
		return newWorker.getMediaSource();
	}

	private DownloadQueueWorkItem findWorkerWithAudioForItem(CollectionItem item) {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.hasMediaSourceFor(item)) {
				return worker;
			}
		}
		return null;
	}

	public boolean isStreaming(CollectionItem item) {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.hasMediaSourceFor(item)) {
				return true;
			}
		}
		return false;
	}

	public boolean isDownloading(CollectionItem item) {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.isDownloading(item)) {
				return true;
			}
		}
		return false;
	}

	private DownloadQueueWorkItem findIdleWorker() {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.isIdle()) {
				return worker;
			}
		}
		return null;
	}

	private DownloadQueueWorkItem findWorkerToInterrupt() {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.canBeInterrupted()) {
				return worker;
			}
		}
		return null;
	}

	private synchronized void downloadNext() {

		if (api.isOffline()) {
			return;
		}

		DownloadQueueWorkItem worker = findIdleWorker();
		if (worker == null) {
			return;
		}

		CollectionItem nextItem = playbackQueue.getNextItemToDownload(player.getCurrentItem(), offlineCache, this);
		if (nextItem != null) {
			if (!offlineCache.makeSpace(nextItem)) {
				return;
			}
			worker.assignItem(nextItem);
			worker.beginBackgroundDownload();
		}
	}
}
