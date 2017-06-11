package agersant.polaris.api.remote;

import android.content.Intent;
import android.media.MediaDataSource;
import android.os.AsyncTask;

import java.io.File;
import java.io.IOException;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisService;

/**
 * Created by agersant on 1/11/2017.
 */

class DownloadQueueWorkItem {

	static final int MAX_ATTEMPTS = 10;

	private File tempFile;
	private CollectionItem item;
	private DownloadTask job;
	private StreamingMediaDataSource mediaDataSource;
	private PolarisService service;
	private int attempts;

	DownloadQueueWorkItem(File tempFile, PolarisService service) {
		this.tempFile = tempFile;
		this.service = service;
	}

	boolean isHandling(CollectionItem item) {
		return this.item != null && this.item.getPath().equals(item.getPath());
	}

	boolean isIdle() {
		if (job == null) {
			return true;
		}
		AsyncTask.Status status = job.getStatus();
		switch (status) {
			case PENDING:
			case RUNNING:
				return false;
			case FINISHED:
				return !isDataSourceInUse();
		}
		return true;
	}

	private boolean isDataSourceInUse() {
		if (mediaDataSource == null) {
			return false;
		}
		return service.isUsing(mediaDataSource);
	}

	boolean isInterruptible() {
		return !isDataSourceInUse();
	}

	MediaDataSource getMediaDataSource() {
		return mediaDataSource;
	}

	void beginDownload(CollectionItem item) throws IOException {
		assert !isHandling(item);
		stop();
		attempts = 0;
		this.item = item;
		tryDownload();
		broadcast(DownloadQueue.WORKLOAD_CHANGED);
	}

	void tryDownload() throws IOException {
		attempts++;

		if (tempFile.exists()) {
			if (!tempFile.delete()) {
				System.out.println("Could not delete streaming file");
			}
		}

		if (!tempFile.createNewFile()) {
			System.out.println("Could not create streaming file");
		}

		System.out.println("Downloading " + item.getPath() + " (attempt #" + attempts + ")" );
		mediaDataSource = new StreamingMediaDataSource(tempFile);
		job = new DownloadTask(service, this, item, tempFile);
		broadcast(DownloadQueue.WORKLOAD_CHANGED);

		job.execute();
	}

	void setContentLength(int length) {
		mediaDataSource.setContentLength(length);
	}

	void onJobSuccess() {
		mediaDataSource.markAsComplete();
	}

	void onJobError() {
		float mediaProgress = 0.f;
		boolean isPaused = true;

		boolean stopActiveMedia = isDataSourceInUse();
		if (stopActiveMedia) {
			System.out.println("Stopping active datasource");
			isPaused = !service.isPlaying();
			mediaProgress = service.getProgress();
			service.stop();
		}

		if (attempts < MAX_ATTEMPTS) {
			try {
				endAttempt();
				tryDownload();
				if (stopActiveMedia) {
					System.out.println("Resuming playback from " + mediaProgress + "%");
					service.play(item);
					service.seekTo(mediaProgress);
					if (isPaused) {
						service.pause();
					}
				}
				return;
			} catch (Exception e) {
				System.out.println("Error while retrying download (" + item.getPath() + "): " + e );
			}
		} else {
			System.out.println("Giving up on " + item.getPath() );
		}

		stop();
		broadcast(DownloadQueue.WORKLOAD_CHANGED);
	}

	private void endAttempt() {
		assert !isDataSourceInUse();
		if (job != null) {
			job.cancel(true);
			job = null;
		}
		if (mediaDataSource != null) {
			try {
				mediaDataSource.close();
			} catch (Exception e) {
				System.out.println("Error while closing data source for download queue work item");
			}
			mediaDataSource = null;
		}
	}

	private void stop() {
		endAttempt();
		item = null;
	}

	private void broadcast(String event) {
		PolarisApplication application = PolarisApplication.getInstance();
		Intent intent = new Intent();
		intent.setAction(event);
		application.sendBroadcast(intent);
	}

}
