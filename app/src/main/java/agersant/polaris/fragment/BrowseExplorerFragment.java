package agersant.polaris.fragment;


import android.app.Fragment;
import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.activity.browse.ExplorerAdapter;
import agersant.polaris.activity.browse.ExplorerTouchCallback;


public class BrowseExplorerFragment extends Fragment {

    private ExplorerAdapter adapter;
    private ArrayList<CollectionItem> items;

    public BrowseExplorerFragment() {
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_browse_explorer, container, false);

        RecyclerView recyclerView = (RecyclerView) view.findViewById(R.id.browse_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(getActivity()));

        ItemTouchHelper.Callback callback = new ExplorerTouchCallback();
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);

        adapter = new ExplorerAdapter();
        recyclerView.setAdapter(adapter);
        if (items != null) {
            adapter.setItems(items);
        }

        return view;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        adapter = null;
    }

    public void setItems(ArrayList<CollectionItem> items) {
        this.items = items;
        if (adapter != null) {
            adapter.setItems(items);
        }
    }

}
