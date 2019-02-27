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

	abstract String getMediaURL(String path);

	public Uri getContentUri(String path) {
		String url = getMediaURL(path);
		return Uri.parse(url);
	}

	public ResponseBody serve(String path) throws IOException {
		Request request = new Request.Builder().url(getContentUri(path).toString()).build();
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
