package agersant.polaris.features.browse;

import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;


abstract class BrowseAdapter
		extends RecyclerView.Adapter<BrowseItemHolder> {

	ArrayList<? extends CollectionItem> items;

	BrowseAdapter() {
		super();
		setItems(new ArrayList<>());
	}

	void setItems(ArrayList<? extends CollectionItem> items) {
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
