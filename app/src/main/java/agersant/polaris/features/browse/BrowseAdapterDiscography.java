package agersant.polaris.features.browse;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import agersant.polaris.R;

/**
 * Created by agersant on 12/11/2016.
 */

class BrowseAdapterDiscography extends BrowseAdapter {

	BrowseAdapterDiscography() {
		super();
	}

	@Override
	public BrowseItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		View itemQueueStatusView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_item_queued, parent, false);
		View itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_discography_item, parent, false);
		return new BrowseItemHolderDiscography(this, itemView, itemQueueStatusView);
	}

}
