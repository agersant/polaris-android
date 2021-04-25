package agersant.polaris.features.browse;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.API;


class BrowseAdapterDiscography extends BrowseAdapter {

    private final API api;
    private final PlaybackQueue playbackQueue;

    BrowseAdapterDiscography(API api, PlaybackQueue playbackQueue) {
        super();
        this.api = api;
        this.playbackQueue = playbackQueue;
    }

    @Override
    public BrowseItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View itemQueueStatusView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_item_queued, parent, false);
        View itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_discography_item, parent, false);
        return new BrowseItemHolderDiscography(api, playbackQueue, this, itemView, itemQueueStatusView);
    }

}
