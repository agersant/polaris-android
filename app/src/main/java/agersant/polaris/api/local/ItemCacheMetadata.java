package agersant.polaris.api.local;

import java.io.Serializable;
import java.util.Date;

/**
 * Created by agersant on 4/11/2017.
 */

class ItemCacheMetadata implements Serializable {
	Date lastUse;

	ItemCacheMetadata() {
		lastUse = new Date();
	}
}