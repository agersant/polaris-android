package agersant.polaris.api.remote;

import com.google.android.exoplayer2.source.MediaSource;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;

/**
 * Created by agersant on 12/25/2016.
 */

public class DownloadQueue {

	public static final String WORKLOAD_CHANGED = "WORKLOAD_CHANGED";

	private PolarisService service;
	private Timer timer;
	private ArrayList<DownloadQueueWorkItem> workers;

	public DownloadQueue(PolarisService service) {
		this.service = service;

		workers = new ArrayList<>();
		for (int i = 0; i < 2; i++) {
			File file = new File(service.getExternalCacheDir(), "stream" + i + ".tmp");
			DownloadQueueWorkItem worker = new DownloadQueueWorkItem(file, service);
			workers.add(worker);
		}
		timer = new Timer();
		timer.scheduleAtFixedRate(new TimerTask() {
			@Override
			public void run() {
				downloadNext();
			}
		}, 1500, 500);
	}

	public synchronized MediaSource getAudio(CollectionItem item) throws IOException {
		DownloadQueueWorkItem existingWorker = findWorkerWithAudioForItem(item);
		if (existingWorker != null) {
			existingWorker.stopBackgroundDownload();
			return existingWorker.getMediaSource();
		}

		DownloadQueueWorkItem newWorker = findIdleWorker();
		if (newWorker == null) {
			newWorker = findInterruptibleWorker();
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

	private DownloadQueueWorkItem findInterruptibleWorker() {
		for (DownloadQueueWorkItem worker : workers) {
			if (worker.isInterruptible()) {
				return worker;
			}
		}
		return null;
	}

	private synchronized void downloadNext() {

		if (service.isOffline()) {
			return;
		}

		DownloadQueueWorkItem worker = findIdleWorker();
		if (worker == null) {
			return;
		}

		CollectionItem nextItem = service.getNextItemToDownload();
		if (nextItem != null) {
			if (!service.makeSpace(nextItem)) {
				return;
			}
			try {
				worker.assignItem(nextItem);
				worker.beginBackgroundDownload();
			} catch (IOException e) {
				System.out.println("Error while downloading item ahead of time: " + e);
			}
		}
	}
}
