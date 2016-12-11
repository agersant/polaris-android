package agersant.polaris.features.browse;

/**
 * Created by agersant on 12/11/2016.
 */

import android.content.Context;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;

class BrowseViewDiscography extends BrowseViewContent {

    private BrowseAdapter adapter;

    public BrowseViewDiscography(Context context) {
        super(context);

        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.view_browse_discography, this, true);

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        ItemTouchHelper.Callback callback = new BrowseTouchCallback();
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);

        adapter = new BrowseAdapterDiscography();
        recyclerView.setAdapter(adapter);
    }

    @Override
    void setItems(ArrayList<CollectionItem> items) {
        adapter.setItems(items);
    }

}
