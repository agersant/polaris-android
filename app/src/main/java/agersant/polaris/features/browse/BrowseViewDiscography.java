package agersant.polaris.features.browse;

import android.content.Context;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.ItemTouchHelper;
import android.view.LayoutInflater;

import com.orangegangsters.github.swipyrefreshlayout.library.SwipyRefreshLayout;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.API;


class BrowseViewDiscography extends BrowseViewContent {

	private final BrowseAdapter adapter;
	private final SwipyRefreshLayout swipeRefresh;

	public BrowseViewDiscography(Context context) {
		super(context);
		throw new UnsupportedOperationException();
	}

	public BrowseViewDiscography(Context context, API api, PlaybackQueue playbackQueue) {
		super(context);

		LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
		inflater.inflate(R.layout.view_browse_discography, this, true);

		RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
		recyclerView.setHasFixedSize(true);
		recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

		ItemTouchHelper.Callback callback = new BrowseTouchCallback();
		ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
		itemTouchHelper.attachToRecyclerView(recyclerView);

		adapter = new BrowseAdapterDiscography(api, playbackQueue);
		recyclerView.setAdapter(adapter);

		swipeRefresh = (SwipyRefreshLayout) findViewById(R.id.swipe_refresh);
	}

	@Override
	void setItems(ArrayList<? extends CollectionItem> items) {
		adapter.setItems(items);
	}

	@Override
	void setOnRefreshListener(SwipyRefreshLayout.OnRefreshListener listener) {
		swipeRefresh.setEnabled(listener != null);
		swipeRefresh.setOnRefreshListener(listener);
	}
}
