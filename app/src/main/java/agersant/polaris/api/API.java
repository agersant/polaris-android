package agersant.polaris.api;

import android.content.Context;
import android.content.SharedPreferences;
import android.media.MediaDataSource;
import android.preference.PreferenceManager;

import com.android.volley.Response;

import java.io.IOException;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.remote.ServerAPI;

/**
 * Created by agersant on 12/25/2016.
 */

public class API {

	private static API instance;
	private ServerAPI serverAPI;
	private LocalAPI localAPI;
	private SharedPreferences preferences;
	private String offlineModePreferenceKey;

	private API(Context context) {
		preferences = PreferenceManager.getDefaultSharedPreferences(context);
		offlineModePreferenceKey = context.getString(R.string.pref_key_offline);
		serverAPI = ServerAPI.getInstance();
		localAPI = LocalAPI.getInstance();
	}

	public static void init(Context context) {
		instance = new API(context);
	}

	public static API getInstance() {
		return instance;
	}

	private boolean isOffline() {
		return preferences.getBoolean(offlineModePreferenceKey, false);
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
