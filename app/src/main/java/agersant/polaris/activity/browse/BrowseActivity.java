package agersant.polaris.activity.browse;

import android.content.Intent;
import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.widget.ProgressBar;

import com.android.volley.Response;

import org.json.JSONArray;
import org.json.JSONObject;

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
        Response.Listener<JSONArray> success = new Response.Listener<JSONArray>() {
            @Override
            public void onResponse(JSONArray response) {
                setContent(response);
            }
        };
        ServerAPI server = ServerAPI.getInstance(getApplicationContext());
        server.browse(path, success);
    }

    private void setContent(JSONArray content) {
        progressBar.setVisibility(View.GONE);

        ArrayList<CollectionItem> newItems = new ArrayList<>();
        for (int i = 0; i < content.length(); i++) {
            JSONObject item = null;
            try {
                item = content.getJSONObject(i);
            } catch (Exception e) {
            }
            assert item != null;
            CollectionItem browseItem = new CollectionItem(item);
            newItems.add(browseItem);
        }
        adapter.setItems(newItems);
    }
}
