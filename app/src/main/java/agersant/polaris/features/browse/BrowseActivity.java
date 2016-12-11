package agersant.polaris.features.browse;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
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
    private ViewGroup contentHolder;

    public BrowseActivity() {
        super(R.string.collection, R.id.nav_collection);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_browse);
        super.onCreate(savedInstanceState);

        progressBar = (ProgressBar) findViewById(R.id.progress_bar);
        contentHolder = (ViewGroup) findViewById(R.id.browse_content_holder);

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
        BrowseContentView contentView = null;
        switch (getDisplayModeForItems(items)) {
            case EXPLORER:
                contentView = new BrowseExplorerView(this);
                break;
            case ALBUM:
                contentView = new BrowseAlbumView(this);
                break;
            case DISCOGRAPHY:
                contentView = new BrowseDiscographyView(this);
                break;
        }
        contentView.setItems(items);
        contentHolder.addView(contentView);
    }

    private DisplayMode getDisplayModeForItems(ArrayList<CollectionItem> items) {
        if (items.isEmpty()) {
            return DisplayMode.EXPLORER;
        }

        String album = items.get(0).getAlbum();
        boolean allSongs = true;
        boolean allDirectories = true;
        boolean allHaveArtwork = true;
        boolean allHaveAlbum = album != null;
        boolean allSameAlbum = true;
        for (CollectionItem item : items) {
            allSongs &= !item.isDirectory();
            allDirectories &= item.isDirectory();
            allHaveArtwork &= item.getArtwork() != null;
            allHaveAlbum &= item.getAlbum() != null;
            allSameAlbum &= album != null && album.equals(item.getAlbum());
        }

        if (allDirectories && allHaveArtwork && allHaveAlbum) {
            return DisplayMode.DISCOGRAPHY;
        }

        if (album != null && allSongs && allSameAlbum) {
            return DisplayMode.ALBUM;
        }

        return DisplayMode.EXPLORER;
    }

    private enum DisplayMode {
        EXPLORER,
        DISCOGRAPHY,
        ALBUM,
    }
}
