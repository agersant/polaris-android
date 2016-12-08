package agersant.polaris.features.browse;

import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ProgressBar;

import com.android.volley.Response;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.api.ServerAPI;
import agersant.polaris.features.PolarisActivity;

public class BrowseActivity extends PolarisActivity {

    public static final String PATH = "PATH";
    private ProgressBar progressBar;

    public BrowseActivity() {
        super(R.string.collection, R.id.nav_collection);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_browse);
        super.onCreate(savedInstanceState);

        progressBar = (ProgressBar) findViewById(R.id.progress_bar);

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
                displayContent(response);
            }
        };
        ServerAPI server = ServerAPI.getInstance(getApplicationContext());
        server.browse(path, success);
    }

    private void displayContent(ArrayList<CollectionItem> items) {
        FragmentManager fragmentManager = getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        ExplorerFragment fragment = new ExplorerFragment();
        fragmentTransaction.add(R.id.browse_content_holder, fragment);
        fragment.setItems(items);
        fragmentTransaction.commit();
    }
}
