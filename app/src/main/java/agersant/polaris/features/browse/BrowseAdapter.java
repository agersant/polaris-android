package agersant.polaris.features.browse;

import android.support.v7.widget.RecyclerView;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;


abstract class BrowseAdapter
		extends RecyclerView.Adapter<BrowseItemHolder> {

	private ArrayList<CollectionItem> items;

	BrowseAdapter() {
		super();
		setItems(new ArrayList<CollectionItem>());
	}

	void setItems(ArrayList<CollectionItem> items) {
		this.items = items;
		notifyDataSetChanged();
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
