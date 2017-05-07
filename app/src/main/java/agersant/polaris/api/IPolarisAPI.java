package agersant.polaris.api;

import android.media.MediaDataSource;
import android.widget.ImageView;

import java.io.IOException;

import agersant.polaris.CollectionItem;

/**
 * Created by agersant on 12/25/2016.
 */

public interface IPolarisAPI {

	void getImage(CollectionItem item, ImageView view);

	MediaDataSource getAudio(CollectionItem item) throws IOException;

	void browse(String path, final ItemsCallback handlers);

	void flatten(String path, final ItemsCallback handlers);

}
