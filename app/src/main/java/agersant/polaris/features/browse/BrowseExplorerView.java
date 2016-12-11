package agersant.polaris.features.browse;


import android.content.Context;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;


public class BrowseExplorerView extends BrowseContentView {

    private BrowseAdapter adapter;

    public BrowseExplorerView(Context context) {
        super(context);

        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.view_browse_explorer, this, true);

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        ItemTouchHelper.Callback callback = new BrowseTouchCallback();
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);

        adapter = new BrowseAdapterExplorer();
        recyclerView.setAdapter(adapter);
    }

    @Override
    void setItems(ArrayList<CollectionItem> items) {
        adapter.setItems(items);
    }

}
