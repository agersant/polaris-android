package agersant.polaris.api.remote;

import android.net.Uri;

import com.google.android.exoplayer2.source.MediaSource;

import java.io.IOException;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.ItemsCallback;
import okhttp3.Request;
import okhttp3.ResponseBody;

abstract class APIBase {

	private final DownloadQueue downloadQueue;
	final RequestQueue requestQueue;

	APIBase(DownloadQueue downloadQueue, RequestQueue requestQueue) {
		this.downloadQueue = downloadQueue;
		this.requestQueue = requestQueue;
	}

	abstract String getAudioURL(String path);

	abstract String getThumbnailURL(String path);

	public Uri getAudioUri(String path) {
		String url = getAudioURL(path);
		return Uri.parse(url);
	}

	public Uri getThumbnailUri(String path) {
		String url = getThumbnailURL(path);
		return Uri.parse(url);
	}

	public ResponseBody getAudio(String path) throws IOException {
		Request request = new Request.Builder().url(getAudioUri(path).toString()).build();
		return requestQueue.requestSync(request);
	}

	public ResponseBody getThumbnail(String path) throws IOException {
		Request request = new Request.Builder().url(getThumbnailUri(path).toString()).build();
		return requestQueue.requestSync(request);
	}

	abstract void getAlbums(String url, final ItemsCallback handlers);

	public void getRandomAlbums(ItemsCallback handlers) {
		String requestURL = ServerAPI.getAPIRootURL() + "/random/";
		getAlbums(requestURL, handlers);
	}

	public void getRecentAlbums(ItemsCallback handlers) {
		String requestURL = ServerAPI.getAPIRootURL() + "/recent/";
		getAlbums(requestURL, handlers);
	}

	public MediaSource getAudio(CollectionItem item) {
		return downloadQueue.getAudio(item);
	}

}
