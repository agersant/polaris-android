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

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        recyclerView.setLayoutManager(linearLayoutManager);

        adapter = new ExplorerAdapter();
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

        ArrayList<ExplorerItem> newItems = new ArrayList<>();
        for (int i = 0; i < content.length(); i++) {
            try {
                JSONObject item = content.getJSONObject(i);
                boolean isDirectory = item.getString("variant").equals("Directory");
                JSONObject fields = item.getJSONArray("fields").getJSONObject(0);
                String name = fields.getString("path");
                ExplorerItem explorerItem = new ExplorerItem(name, isDirectory);
                newItems.add(explorerItem);
            } catch (Exception e) {
                System.err.println("Unexpected response structure");
            }
        }
        adapter.setItems(newItems);
    }
}
