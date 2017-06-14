package agersant.polaris.features.browse;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.view.View;
import android.widget.Button;

import agersant.polaris.PolarisService;
import agersant.polaris.R;
import agersant.polaris.features.PolarisActivity;

public class CollectionActivity extends PolarisActivity {

	private PolarisService service;
	private Button randomAlbums;
	private Button recentAlbums;

	public CollectionActivity() {
		super(R.string.collection, R.id.nav_collection);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
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
	private ServiceConnection serviceConnection = new ServiceConnection() {
		@Override
		public void onServiceDisconnected(ComponentName name) {
			service = null;
		}

		@Override
		public void onServiceConnected(ComponentName name, IBinder iBinder) {
			service = ((PolarisService.PolarisBinder) iBinder).getService();
			updateButtons();
		}
	};

	@Override
	public void onStart() {
		Intent intent = new Intent(this, PolarisService.class);
		bindService(intent, serviceConnection, BIND_AUTO_CREATE);
		startService(intent);
		super.onStart();
	}

	@Override
	public void onStop() {
		if (service != null) {
			unbindService(serviceConnection);
			service = null;
		}
		super.onStop();
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
		boolean isOffline = service == null || service.isOffline();
		randomAlbums.setEnabled(!isOffline);
		recentAlbums.setEnabled(!isOffline);
	}
}
