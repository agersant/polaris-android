package agersant.polaris.features.browse;


import android.content.Context;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;


public class ExplorerFolderView extends ExplorerContentView {

    private ExplorerAdapter adapter;

    public ExplorerFolderView(Context context) {
        super(context);

        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.view_explorer_folder, this, true);

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        ItemTouchHelper.Callback callback = new ExplorerTouchCallback();
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);

        adapter = new ExplorerAdapter();
        recyclerView.setAdapter(adapter);
    }

    @Override
    void setItems(ArrayList<CollectionItem> items) {
        adapter.setItems(items);
    }

}
