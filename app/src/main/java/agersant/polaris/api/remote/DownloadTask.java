package agersant.polaris.api.remote;

import android.os.AsyncTask;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import okhttp3.ResponseBody;

/**
 * Created by agersant on 12/26/2016.
 */

class DownloadTask extends AsyncTask<Object, Integer, Integer> {

	private static final int BUFFER_SIZE = 1024 * 64; // 64 kB

	private CollectionItem item;
	private String path;
	private File outFile;
	private boolean reachedEOF;
	private DownloadQueueWorkItem workItem;
	private PolarisService service;

	DownloadTask(PolarisService service, DownloadQueueWorkItem workItem, CollectionItem item, File outFile) {
		this.workItem = workItem;
		this.item = item;
		this.outFile = outFile;
		this.service = service;
		path = item.getPath();
		reachedEOF = false;
	}

	public String getPath() {
		return item.getPath();
	}

	@Override
	protected Integer doInBackground(Object... params) {

		ResponseBody responseBody;
		try {
			responseBody = service.getServerAPI().serve(path);
		} catch (Exception e) {
			System.out.println("Error establishing stream connection: " + e);
			return 1;
		}

		if (responseBody == null) {
			System.out.println("Stream content has no response");
			return 1;
		}
		long contentLength = responseBody.contentLength();
		workItem.setContentLength((int) contentLength);

		try (InputStream inputStream = responseBody.byteStream();
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
			try (FileInputStream audioStreamFile = new FileInputStream(outFile)) {
				service.saveAudio(item, audioStreamFile);
			} catch (IOException e) {
				System.out.println("Error while storing item to offline cache: " + e);
			}
		}
	}

	@Override
	protected void onPostExecute(Integer result) {
		if (reachedEOF) {
			workItem.onJobSuccess();
		} else {
			workItem.onJobError();
		}
	}

}
