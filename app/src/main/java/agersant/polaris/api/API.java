package agersant.polaris.api;

import android.media.MediaDataSource;

import com.android.volley.Response;

import java.io.IOException;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.remote.ServerAPI;

/**
 * Created by agersant on 12/25/2016.
 */

public class API {

	private static API instance;
	private ServerAPI serverAPI;
	private LocalAPI localAPI;

	private API() {
		serverAPI = ServerAPI.getInstance();
		localAPI = LocalAPI.getInstance();
	}

	public static void init() {
		instance = new API();
	}

	public static API getInstance() {
		return instance;
	}

	private boolean isOffline() {
		return false;
	}

	public MediaDataSource getAudio(CollectionItem item) throws IOException {
		return getAPI().getAudio(item);
	}

	public void browse(String path, final Response.Listener<ArrayList<CollectionItem>> success, Response.ErrorListener failure) {
		getAPI().browse(path, success, failure);
	}

	private IPolarisAPI getAPI() {
		if (isOffline()) {
			return localAPI;
		}
		return serverAPI;
	}

}
