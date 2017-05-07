package agersant.polaris.features.browse;

import android.content.Context;
import android.widget.FrameLayout;

import com.orangegangsters.github.swipyrefreshlayout.library.SwipyRefreshLayout;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;

/**
 * Created by agersant on 12/7/2016.
 */

abstract class BrowseViewContent extends FrameLayout {

	public BrowseViewContent(Context context) {
		super(context);
	}

	void setItems(ArrayList<? extends CollectionItem> items) {
	}

	void setOnRefreshListener(SwipyRefreshLayout.OnRefreshListener listener) {

	}
}
