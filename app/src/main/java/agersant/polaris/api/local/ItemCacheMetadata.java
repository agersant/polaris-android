package agersant.polaris.api.local;

import java.io.Serializable;
import java.util.Date;


class ItemCacheMetadata implements Serializable {
	Date lastUse;

	ItemCacheMetadata() {
		lastUse = new Date();
	}
}