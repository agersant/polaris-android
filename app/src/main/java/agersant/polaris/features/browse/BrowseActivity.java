package agersant.polaris.features.browse;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.view.Menu;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ProgressBar;

import com.orangegangsters.github.swipyrefreshlayout.library.SwipyRefreshLayout;
import com.orangegangsters.github.swipyrefreshlayout.library.SwipyRefreshLayoutDirection;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;
import agersant.polaris.api.ItemsCallback;
import agersant.polaris.features.PolarisActivity;

public class BrowseActivity extends PolarisActivity {

	public static final String PATH = "PATH";
	public static final String NAVIGATION_MODE = "NAVIGATION_MODE";
	private ProgressBar progressBar;
	private View errorMessage;
	private ViewGroup contentHolder;
	private ItemsCallback fetchCallback;
	private NavigationMode navigationMode;
	private SwipyRefreshLayout.OnRefreshListener onRefresh;
	private ArrayList<? extends CollectionItem> items;
	private PolarisService service;

	public BrowseActivity() {
		super(R.string.collection, R.id.nav_collection);
	}
	private ServiceConnection serviceConnection = new ServiceConnection() {
		@Override
		public void onServiceDisconnected(ComponentName name) {
			service = null;
		}

		@Override
		public void onServiceConnected(ComponentName name, IBinder iBinder) {
			service = ((PolarisService.PolarisBinder) iBinder).getService();
			loadContent();
			displayContent();
		}
	};

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		setContentView(R.layout.activity_browse);
		super.onCreate(savedInstanceState);

		errorMessage = findViewById(R.id.browse_error_message);
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
						that.items = items;
						that.displayContent();
					}
				});
			}

			@Override
			public void onError() {
				that.runOnUiThread(new Runnable() {
					@Override
					public void run() {
						progressBar.setVisibility(View.GONE);
						errorMessage.setVisibility(View.VISIBLE);
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

	}

	@Override
	public void onStart() {
		Intent intent = new Intent(this, PolarisService.class);
		startService(intent);
		bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
		super.onStart();
	}

	@Override
	public void onStop() {
		if (service != null) {
			unbindService(serviceConnection);
		}
		super.onStop();
	}

	private void loadContent() {
		progressBar.setVisibility(View.VISIBLE);
		errorMessage.setVisibility(View.GONE);
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
			case RECENT: {
				loadRecent();
				break;
			}
		}
	}

	public void retry(View view) {
		loadContent();
	}

	@Override
	public void finish() {
		super.finish();
		overridePendingTransition(0, 0);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		return true;
	}

	private void loadPath(String path) {
		service.getAPI().browse(path, fetchCallback);
	}

	private void loadRandom() {
		service.getServerAPI().getRandomAlbums(fetchCallback);
	}

	private void loadRecent() {
		service.getServerAPI().getRecentAlbums(fetchCallback);
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
		RECENT,
	}

	private void displayContent() {
		if (service == null) {
			return;
		}
		if (items == null) {
			return;
		}

		BrowseViewContent contentView = null;
		switch (getDisplayModeForItems(items)) {
			case EXPLORER:
				contentView = new BrowseViewExplorer(this, service);
				break;
			case ALBUM:
				contentView = new BrowseViewAlbum(this, service);
				break;
			case DISCOGRAPHY:
				contentView = new BrowseViewDiscography(this, service);
				break;
		}

		contentView.setItems(items);
		contentView.setOnRefreshListener(onRefresh);
		contentHolder.addView(contentView);
	}
}
