package agersant.polaris.features.browse;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import agersant.polaris.PlaybackQueue;
import agersant.polaris.PolarisService;
import agersant.polaris.R;
import agersant.polaris.api.API;


class BrowseAdapterExplorer extends BrowseAdapter {

	private final API api;
	private final PlaybackQueue playbackQueue;

	BrowseAdapterExplorer(API api, PlaybackQueue playbackQueue) {
		super();
		this.api = api;
		this.playbackQueue = playbackQueue;
	}

	@Override
	public BrowseItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		View itemQueueStatusView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_item_queued, parent, false);
		View itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_explorer_item, parent, false);
		return new BrowseItemHolderExplorer(api, playbackQueue, this, itemView, itemQueueStatusView);
	}

}
