package agersant.polaris.features.browse;

import android.content.Context;
import android.widget.FrameLayout;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;

/**
 * Created by agersant on 12/7/2016.
 */

abstract class BrowseViewContent extends FrameLayout {

	public BrowseViewContent(Context context) {
		super(context);
	}

	void setItems(ArrayList<CollectionItem> items) {
	}
}
