package agersant.polaris.activity.browse;

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;

import com.android.volley.Response;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;

import agersant.polaris.R;
import agersant.polaris.api.ServerAPI;

public class BrowseActivity extends AppCompatActivity {

    private ExplorerAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_browse);

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.browse_recycler_view);
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        recyclerView.setLayoutManager(linearLayoutManager);

        adapter = new ExplorerAdapter(this);
        recyclerView.setAdapter(adapter);

        browseTo("");
    }

    void browseTo(String path) {
        final BrowseActivity that = this;
        Response.Listener<JSONArray> success = new Response.Listener<JSONArray>() {
            @Override
            public void onResponse(JSONArray response) {
                that.onReceiveContent(response);
            }
        };

        ServerAPI server = ServerAPI.getInstance(getApplicationContext());
        server.browse(path, success);
    }

    private void onReceiveContent(JSONArray content) {
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
