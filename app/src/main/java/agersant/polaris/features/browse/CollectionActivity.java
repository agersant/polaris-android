package agersant.polaris.features.browse;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.view.View;
import android.widget.Button;

import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisService;
import agersant.polaris.PolarisState;
import agersant.polaris.R;
import agersant.polaris.api.API;
import agersant.polaris.features.PolarisActivity;

public class CollectionActivity extends PolarisActivity {

	private Button randomAlbums;
	private Button recentAlbums;
	private API api;

	public CollectionActivity() {
		super(R.string.collection, R.id.nav_collection);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		setContentView(R.layout.activity_collection);
		super.onCreate(savedInstanceState);

		PolarisState state = PolarisApplication.getState();
		this.api = state.api;

		randomAlbums = findViewById(R.id.random);
		recentAlbums = findViewById(R.id.recently_added);

		// Disable unimplemented features
		{
			Button button;
			button = findViewById(R.id.playlists);
			button.setEnabled(false);
		}
	}


	@Override
	public void onStart() {
		super.onStart();
		updateButtons();
	}

	public void browseDirectories(View view) {
		Context context = view.getContext();
		Intent intent = new Intent(context, BrowseActivity.class);
		intent.putExtra(BrowseActivity.NAVIGATION_MODE, BrowseActivity.NavigationMode.PATH);
		intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
		context.startActivity(intent);
	}

	public void browseRandom(View view) {
		Context context = view.getContext();
		Intent intent = new Intent(context, BrowseActivity.class);
		intent.putExtra(BrowseActivity.NAVIGATION_MODE, BrowseActivity.NavigationMode.RANDOM);
		intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
		context.startActivity(intent);
	}

	public void browseRecent(View view) {
		Context context = view.getContext();
		Intent intent = new Intent(context, BrowseActivity.class);
		intent.putExtra(BrowseActivity.NAVIGATION_MODE, BrowseActivity.NavigationMode.RECENT);
		intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
		context.startActivity(intent);
	}

	@Override
	public void onResume() {
		super.onResume();
		updateButtons();
	}

	private void updateButtons() {
		boolean isOffline = api.isOffline();
		randomAlbums.setEnabled(!isOffline);
		recentAlbums.setEnabled(!isOffline);
	}
}
