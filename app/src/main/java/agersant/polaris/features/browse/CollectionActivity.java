package agersant.polaris.features.browse;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.StrictMode;
import android.view.View;
import android.widget.Button;

import agersant.polaris.BuildConfig;
import agersant.polaris.R;
import agersant.polaris.api.API;
import agersant.polaris.features.PolarisActivity;

public class CollectionActivity extends PolarisActivity {

	private Button randomAlbums;
	private Button recentAlbums;

	public CollectionActivity() {
		super(R.string.collection, R.id.nav_collection);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {

		if (BuildConfig.DEBUG) {
			StrictMode.setThreadPolicy(new StrictMode.ThreadPolicy.Builder()
					.detectAll()
					.penaltyDeath()
					.build());
		}

		setContentView(R.layout.activity_collection);
		super.onCreate(savedInstanceState);

		randomAlbums = (Button) findViewById(R.id.random);
		recentAlbums = (Button) findViewById(R.id.recently_added);

		// Disable unimplemented features
		{
			Button button;
			button = (Button) findViewById(R.id.playlists);
			button.setEnabled(false);
		}
	}

	@Override
	public void onResume() {
		super.onResume();
		API api = API.getInstance();
		boolean isOffline = api.isOffline();
		randomAlbums.setEnabled(!isOffline);
		recentAlbums.setEnabled(!isOffline);
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
}
