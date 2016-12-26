package agersant.polaris.cache;

import android.media.MediaDataSource;

import com.android.volley.Response;

import java.io.IOException;
import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.IPolarisAPI;

/**
 * Created by agersant on 12/25/2016.
 */

public class LocalAPI implements IPolarisAPI {

	private static LocalAPI instance;

	private LocalAPI() {

	}

	public static void init() {
		instance = new LocalAPI();
	}

	public static LocalAPI getInstance() {
		return instance;
	}

	@Override
	public MediaDataSource getAudio(String path) throws IOException {
		// TODO
		return null;
	}

	public void browse(String path, Response.Listener<ArrayList<CollectionItem>> success, Response.ErrorListener failure) {
		// TODO
	}
}
