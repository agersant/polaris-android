package agersant.polaris.api;

import android.os.AsyncTask;

import com.google.android.exoplayer2.source.MediaSource;

import java.io.IOException;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.remote.ServerAPI;

public class FetchAudioTask extends AsyncTask<Void, Void, MediaSource> {

	private final CollectionItem item;
	private final API api;
	private final LocalAPI localAPI;
	private final ServerAPI serverAPI;
	private final Callback callback;

	private FetchAudioTask(API api, LocalAPI localAPI, ServerAPI serverAPI, CollectionItem item, Callback callback) {
		this.api = api;
		this.localAPI = localAPI;
		this.serverAPI = serverAPI;
		this.item = item;
		this.callback = callback;
	}

	static FetchAudioTask load(API api, LocalAPI localAPI, ServerAPI serverAPI, CollectionItem item, Callback callback) {
		FetchAudioTask task = new FetchAudioTask(api, localAPI, serverAPI, item, callback);
		task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
		return task;
	}

	@Override
	protected MediaSource doInBackground(Void... params) {
		if (localAPI.hasAudio(item)) {
			try {
				return localAPI.getAudio(item);
			} catch (IOException e) {
				System.out.println("IO error while reading offline cache for " + item.getPath());
				return null;
			}
		} else if (!api.isOffline()) {
			try {
				return serverAPI.getAudio(item);
			} catch (IOException e) {
				System.out.println("IO error while querying server API for " + item.getPath());
				return null;
			}
		}
		return null;
	}

	@Override
	protected void onPostExecute(MediaSource mediaSource) {
		if (mediaSource != null) {
			callback.onSuccess(mediaSource);
		}
	}

	public interface Callback {
		void onSuccess(MediaSource mediaSource);
	}
}
