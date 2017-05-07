package agersant.polaris.features.browse;

import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ProgressBar;
import android.widget.Toast;

import com.orangegangsters.github.swipyrefreshlayout.library.SwipyRefreshLayout;
import com.orangegangsters.github.swipyrefreshlayout.library.SwipyRefreshLayoutDirection;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;
import agersant.polaris.api.API;
import agersant.polaris.api.ItemsCallback;
import agersant.polaris.api.remote.ServerAPI;
import agersant.polaris.features.PolarisActivity;

public class BrowseActivity extends PolarisActivity {

	public static final String PATH = "PATH";
	public static final String NAVIGATION_MODE = "NAVIGATION_MODE";
	private ProgressBar progressBar;
	private ViewGroup contentHolder;
	private ItemsCallback fetchCallback;
	private NavigationMode navigationMode;
	private SwipyRefreshLayout.OnRefreshListener onRefresh;

	public BrowseActivity() {
		super(R.string.collection, R.id.nav_collection);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		setContentView(R.layout.activity_browse);
		super.onCreate(savedInstanceState);

		progressBar = (ProgressBar) findViewById(R.id.progress_bar);
		contentHolder = (ViewGroup) findViewById(R.id.browse_content_holder);

		final BrowseActivity that = this;
		fetchCallback = new ItemsCallback() {
			@Override
			public void onSuccess(final ArrayList<? extends CollectionItem> items) {
				that.runOnUiThread(new Runnable() {
					@Override
					public void run() {
						that.progressBar.setVisibility(View.GONE);
						that.displayContent(items);
					}
				});
			}

			@Override
			public void onError() {
				that.runOnUiThread(new Runnable() {
					@Override
					public void run() {
						Toast toast = Toast.makeText(that, R.string.browse_error, Toast.LENGTH_SHORT);
						toast.show();
					}
				});
			}
		};

		Intent intent = getIntent();
		navigationMode = (NavigationMode) intent.getSerializableExtra(BrowseActivity.NAVIGATION_MODE);

		if (navigationMode == NavigationMode.RANDOM) {
			onRefresh = new SwipyRefreshLayout.OnRefreshListener() {
				@Override
				public void onRefresh(SwipyRefreshLayoutDirection direction) {
					loadContent();
				}
			};
		}

		loadContent();
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		return true;
	}

	private void loadContent() {
		Intent intent = getIntent();
		switch (navigationMode) {
			case PATH: {
				String path = intent.getStringExtra(BrowseActivity.PATH);
				if (path == null) {
					path = "";
				}
				loadPath(path);
				break;
			}
			case RANDOM: {
				loadRandom();
				break;
			}
		}
	}

	@Override
	public void finish() {
		super.finish();
		overridePendingTransition(0, 0);
	}

	private void loadPath(String path) {
		API api = API.getInstance();
		api.browse(path, fetchCallback);
	}

	private void loadRandom() {
		ServerAPI server = ServerAPI.getInstance();
		server.getRandomAlbums(fetchCallback);
	}

	private void displayContent(ArrayList<? extends CollectionItem> items) {
		BrowseViewContent contentView = null;
		switch (getDisplayModeForItems(items)) {
			case EXPLORER:
				contentView = new BrowseViewExplorer(this);
				break;
			case ALBUM:
				contentView = new BrowseViewAlbum(this);
				break;
			case DISCOGRAPHY:
				contentView = new BrowseViewDiscography(this);
				break;
		}

		contentView.setItems(items);
		contentView.setOnRefreshListener(onRefresh);
		contentHolder.addView(contentView);
	}

	private DisplayMode getDisplayModeForItems(ArrayList<? extends CollectionItem> items) {
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

	enum NavigationMode {
		PATH,
		RANDOM,
	}

}
