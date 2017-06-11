package agersant.polaris.features.browse;


import android.content.Context;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;

import com.orangegangsters.github.swipyrefreshlayout.library.SwipyRefreshLayout;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;


public class BrowseViewExplorer extends BrowseViewContent {

	private BrowseAdapter adapter;
	private SwipyRefreshLayout swipeRefresh;

	public BrowseViewExplorer(Context context, PolarisService service) {
		super(context);

		LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		inflater.inflate(R.layout.view_browse_explorer, this, true);

		RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
		recyclerView.setHasFixedSize(true);
		recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

		ItemTouchHelper.Callback callback = new BrowseTouchCallback();
		ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
		itemTouchHelper.attachToRecyclerView(recyclerView);

		adapter = new BrowseAdapterExplorer(service);
		recyclerView.setAdapter(adapter);

		swipeRefresh = (SwipyRefreshLayout) findViewById(R.id.swipe_refresh);
	}

	@Override
	void setItems(ArrayList<? extends CollectionItem> items) {
		Collections.sort(items, new Comparator<CollectionItem>() {
			@Override
			public int compare(CollectionItem a, CollectionItem b) {
				return a.getName().compareTo(b.getName());
			}
		});
		adapter.setItems(items);
	}

	@Override
	void setOnRefreshListener(SwipyRefreshLayout.OnRefreshListener listener) {
		swipeRefresh.setEnabled(listener != null);
		swipeRefresh.setOnRefreshListener(listener);
	}
}
