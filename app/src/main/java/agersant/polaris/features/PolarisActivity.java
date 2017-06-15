package agersant.polaris.features;


import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.design.widget.BottomNavigationView;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;

import agersant.polaris.R;
import agersant.polaris.features.browse.CollectionActivity;
import agersant.polaris.features.player.PlayerActivity;
import agersant.polaris.features.queue.QueueActivity;
import agersant.polaris.features.settings.SettingsActivity;

public abstract class PolarisActivity extends AppCompatActivity {

	protected Toolbar toolbar;
	private final int title;
	private final int navigationItem;
	private BottomNavigationView navigationView;

	public PolarisActivity(int title, int navigationItem) {
		this.title = title;
		this.navigationItem = navigationItem;
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		toolbar = (Toolbar) findViewById(R.id.toolbar);
		toolbar.setTitle(title);
		setSupportActionBar(toolbar);

		final PolarisActivity that = this;
		navigationView = (BottomNavigationView) findViewById(R.id.navigation);
		navigationView.setOnNavigationItemSelectedListener(new BottomNavigationView.OnNavigationItemSelectedListener() {
			@Override
			public boolean onNavigationItemSelected(final @NonNull MenuItem menuItem) {
				return that.onNavigationItemSelected(menuItem);
			}
		});
	}

	@Override
	public void onResume() {
		super.onResume();
		highlightNavigationTab();
	}

	private void highlightNavigationTab() {
		Menu menu = navigationView.getMenu();
		for (int i = 0; i < menu.size(); i++) {
			menu.getItem(i).setChecked(false);
		}
		menu.findItem(navigationItem).setChecked(true);
	}

	@Override
	public void onNewIntent(Intent intent) {
		super.onNewIntent(intent);
		overridePendingTransition(0, 0);
	}

	@Override
	public void finish() {
		super.finish();
		overridePendingTransition(0, 0);
	}

	private boolean onNavigationItemSelected(final MenuItem item) {
		switch (item.getItemId()) {
			case R.id.nav_collection:
				openCollection();
				return true;
			case R.id.nav_queue:
				openQueue();
				return true;
			case R.id.nav_now_playing:
				openPlayer();
				return true;
		}
		return false;
	}

	private void openCollection() {
		Intent intent = new Intent(this, CollectionActivity.class);
		intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NO_ANIMATION);
		startActivity(intent);
	}

	private void openQueue() {
		Intent intent = new Intent(this, QueueActivity.class);
		intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NO_ANIMATION);
		startActivity(intent);
	}

	private void openPlayer() {
		Intent intent = new Intent(this, PlayerActivity.class);
		intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NO_ANIMATION);
		startActivity(intent);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.menu_main, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
			case R.id.action_settings:
				Intent intent = new Intent(this, SettingsActivity.class);
				startActivity(intent);
				return true;
			default:
				return super.onOptionsItemSelected(item);
		}
	}
}
