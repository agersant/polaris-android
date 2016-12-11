package agersant.polaris.features.browse;

import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;


class BrowseAdapter
        extends RecyclerView.Adapter<BrowseItemHolder> {

    private ArrayList<CollectionItem> items;
    private DisplayMode mode;

    BrowseAdapter(DisplayMode mode) {
        super();
        this.mode = mode;
        setItems(new ArrayList<CollectionItem>());
    }

    void setItems(ArrayList<CollectionItem> items) {
        this.items = items;
        notifyDataSetChanged();
    }

    @Override
    public BrowseItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View itemQueueStatusView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_item_queued, parent, false);
        View itemView;
        BrowseItemHolder itemHolder = null;
        switch (mode) {
            case FOLDER:
                itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_explorer_item, parent, false);
                itemHolder = new BrowseExplorerItemHolder(this, itemView, itemQueueStatusView);
                break;
            case ALBUM:
                itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_album_item, parent, false);
                itemHolder = new BrowseAlbumItemHolder(this, itemView, itemQueueStatusView);
                break;
            case DISCOGRAPHY: {
                itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.view_browse_discography_item, parent, false);
                itemHolder = new BrowseDiscographyItemHolder(this, itemView, itemQueueStatusView);
                break;
            }
        }
        return itemHolder;
    }

    @Override
    public void onBindViewHolder(BrowseItemHolder holder, int position) {
        holder.bindItem(items.get(position));
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

}
