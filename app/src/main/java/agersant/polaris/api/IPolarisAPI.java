package agersant.polaris.api;

import android.net.Uri;
import android.widget.ImageView;

import java.io.IOException;

import agersant.polaris.CollectionItem;

/**
 * Created by agersant on 12/25/2016.
 */

public interface IPolarisAPI {

	void getImage(CollectionItem item, ImageView view);

	Uri getAudio(CollectionItem item) throws IOException;

	void browse(String path, final ItemsCallback handlers);

	void flatten(String path, final ItemsCallback handlers);

}
