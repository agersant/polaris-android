package agersant.polaris.features.browse;

import android.util.SparseIntArray;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.API;

import static agersant.polaris.features.browse.BrowseAdapterAlbum.AlbumViewType.DISC_HEADER;
import static agersant.polaris.features.browse.BrowseAdapterAlbum.AlbumViewType.TRACK;


class BrowseAdapterAlbum extends BrowseAdapter {

    private SparseIntArray discSizes; // Key is disc number, value is number of tracks
    private int numDiscHeaders;
    private final API api;
    private final PlaybackQueue playbackQueue;

    @Override
    void setItems(ArrayList<? extends CollectionItem> items) {
        discSizes = new SparseIntArray();
        for (CollectionItem item : items) {
            int discNumber = item.getDiscNumber();
            discSizes.put(discNumber, 1 + discSizes.get(discNumber, 0));
        }
        numDiscHeaders = discSizes.size();
        if (numDiscHeaders == 1) {
            numDiscHeaders = 0;
        }
        super.setItems(items);
    }

    BrowseAdapterAlbum(API api, PlaybackQueue playbackQueue) {
        super();
        this.api = api;
        this.playbackQueue = playbackQueue;
    }

    @Override
    public int getItemCount() {
        return super.getItemCount() + numDiscHeaders;
    }

    @Override
    public int getItemViewType(int position) {
        int index = 0;
        for (int discIndex = 0; discIndex < numDiscHeaders; discIndex++) {
            if (position == index) {
                return DISC_HEADER.ordinal();
            }
            index += discSizes.valueAt(discIndex) + 1;
            if (position < index) {
                break;
            }
        }
        return TRACK.ordinal();
    }

    @Override
    public BrowseItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View itemQueueStatusView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_item_queued, parent, false);
        if (viewType == DISC_HEADER.ordinal()) {
            View itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_album_disc, parent, false);
            return new BrowseItemHolderAlbumDiscHeader(api, playbackQueue, this, itemView, itemQueueStatusView);
        } else {
            View itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_album_item, parent, false);
            return new BrowseItemHolderAlbumTrack(api, playbackQueue, this, itemView, itemQueueStatusView);
        }
    }

    @Override
    public void onBindViewHolder(BrowseItemHolder holder, int position) {

        if (holder instanceof BrowseItemHolderAlbumTrack) {

            // Assign track item
            if (numDiscHeaders > 0) {
                int index = 0;
                for (int discIndex = 0; discIndex < discSizes.size(); discIndex++) {
                    if (position <= index) {
                        break;
                    }
                    position--;
                    index += discSizes.valueAt(discIndex);
                }
            }
            holder.bindItem(items.get(position));

        } else {

            // Assign disc number
            BrowseItemHolderAlbumDiscHeader header = (BrowseItemHolderAlbumDiscHeader) holder;
            int index = 0;
            for (int discIndex = 0; discIndex < discSizes.size(); discIndex++) {
                if (position == index) {
                    header.setDiscNumber(discSizes.keyAt(discIndex));
                }
                index += discSizes.valueAt(discIndex) + 1;
            }
        }
    }

    enum AlbumViewType {
        DISC_HEADER,
        TRACK,
    }
}
