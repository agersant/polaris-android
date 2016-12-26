package agersant.polaris;

import android.media.MediaDataSource;

import com.android.volley.Response;

import java.io.IOException;
import java.util.ArrayList;

/**
 * Created by agersant on 12/25/2016.
 */

public interface IPolarisAPI {

	MediaDataSource getAudio(String path) throws IOException;

	void browse(String path, final Response.Listener<ArrayList<CollectionItem>> success, Response.ErrorListener failure);

}
