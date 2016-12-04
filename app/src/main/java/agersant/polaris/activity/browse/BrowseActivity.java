package agersant.polaris.activity.browse;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.View;
import android.widget.ProgressBar;

import com.android.volley.Response;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.activity.PolarisActivity;
import agersant.polaris.api.ServerAPI;

public class BrowseActivity extends PolarisActivity {

    public static final String PATH = "PATH";
    private ExplorerAdapter adapter;
    private ProgressBar progressBar;

    public BrowseActivity() {
        super(R.string.collection, R.id.nav_collection);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_browse);
        super.onCreate(savedInstanceState);

        progressBar = (ProgressBar) findViewById(R.id.progress_bar);

        adapter = new ExplorerAdapter();

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);

        ItemTouchHelper.Callback callback = new ExplorerTouchCallback(adapter);
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);

        Intent intent = getIntent();
        String path = intent.getStringExtra(BrowseActivity.PATH);
        if (path == null) {
            path = "";
        }
        loadPath(path);
    }

    @Override
    public void finish() {
        super.finish();
        overridePendingTransition(0, 0);
    }

    private void loadPath(String path) {
        Response.Listener<ArrayList<CollectionItem>> success = new Response.Listener<ArrayList<CollectionItem>>() {
            @Override
            public void onResponse(ArrayList<CollectionItem> response) {
                progressBar.setVisibility(View.GONE);
                adapter.setItems(response);
            }
        };
        ServerAPI server = ServerAPI.getInstance(getApplicationContext());
        server.browse(path, success);
    }
}
