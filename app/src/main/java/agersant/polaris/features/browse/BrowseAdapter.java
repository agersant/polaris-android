package agersant.polaris.features.browse;

import android.support.v7.widget.RecyclerView;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;


abstract class BrowseAdapter
		extends RecyclerView.Adapter<BrowseItemHolder> {

	private ArrayList<? extends CollectionItem> items;
	protected PolarisService service;

	BrowseAdapter(PolarisService service) {
		super();
		this.service = service;
		setItems(new ArrayList<CollectionItem>());
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

	PolarisService getService() {
		return service;
	}

}
