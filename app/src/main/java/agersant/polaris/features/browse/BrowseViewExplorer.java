package agersant.polaris.features.browse;


import android.content.Context;
import android.view.LayoutInflater;

import com.orangegangsters.github.swipyrefreshlayout.library.SwipyRefreshLayout;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.API;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;


public class BrowseViewExplorer extends BrowseViewContent {

    private final BrowseAdapter adapter;
    private final SwipyRefreshLayout swipeRefresh;

    public BrowseViewExplorer(Context context) {
        super(context);
        throw new UnsupportedOperationException();
    }

    public BrowseViewExplorer(Context context, API api, PlaybackQueue playbackQueue) {
        super(context);

        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.view_browse_explorer, this, true);

        RecyclerView recyclerView = findViewById(R.id.browse_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        ItemTouchHelper.Callback callback = new BrowseTouchCallback();
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);

        adapter = new BrowseAdapterExplorer(api, playbackQueue);
        recyclerView.setAdapter(adapter);

        swipeRefresh = findViewById(R.id.swipe_refresh);
    }

    @Override
    void setItems(ArrayList<? extends CollectionItem> items) {
        Collections.sort(items, new Comparator<CollectionItem>() {
            @Override
            public int compare(CollectionItem a, CollectionItem b) {
                return a.getName().compareToIgnoreCase(b.getName());
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
