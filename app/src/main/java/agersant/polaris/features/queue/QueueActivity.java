package agersant.polaris.features.queue;

import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;

import java.util.Random;

import agersant.polaris.PlaybackQueue;
import agersant.polaris.Player;
import agersant.polaris.PolarisService;
import agersant.polaris.R;
import agersant.polaris.api.local.OfflineCache;
import agersant.polaris.api.remote.DownloadQueue;
import agersant.polaris.features.PolarisActivity;

public class QueueActivity extends PolarisActivity {

	private QueueAdapter adapter;
	private BroadcastReceiver receiver;
	private View tutorial;
	private PolarisService service;

	public QueueActivity() {
		super(R.string.queue, R.id.nav_queue);
	}

	private final ServiceConnection serviceConnection = new ServiceConnection() {
		@Override
		public void onServiceDisconnected(ComponentName name) {
			service = null;
		}

		@Override
		public void onServiceConnected(ComponentName name, IBinder iBinder) {
			service = ((PolarisService.PolarisBinder) iBinder).getService();
			populate();
			updateOrderingIcon();
			updateTutorial();
		}
	};

	private void subscribeToEvents() {
		IntentFilter filter = new IntentFilter();
		filter.addAction(PlaybackQueue.REMOVED_ITEM);
		filter.addAction(PlaybackQueue.REMOVED_ITEMS);
		filter.addAction(PlaybackQueue.QUEUED_ITEMS);
		filter.addAction(Player.PLAYING_TRACK);
		filter.addAction(OfflineCache.AUDIO_CACHED);
		filter.addAction(DownloadQueue.WORKLOAD_CHANGED);
		filter.addAction(OfflineCache.AUDIO_REMOVED_FROM_CACHE);
		receiver = new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				switch (intent.getAction()) {
					case PlaybackQueue.REMOVED_ITEM:
					case PlaybackQueue.REMOVED_ITEMS:
						updateTutorial();
						break;
					case PlaybackQueue.QUEUED_ITEMS:
						updateTutorial();
						// Fallthrough
					case Player.PLAYING_TRACK:
					case OfflineCache.AUDIO_CACHED:
					case OfflineCache.AUDIO_REMOVED_FROM_CACHE:
					case DownloadQueue.WORKLOAD_CHANGED:
						if (adapter != null) {
							adapter.notifyDataSetChanged();
						}
						break;
				}
			}
		};
		registerReceiver(receiver, filter);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		setContentView(R.layout.activity_queue);
		super.onCreate(savedInstanceState);
		tutorial = findViewById(R.id.queue_tutorial);
		updateTutorial();
	}

	private void updateTutorial() {
		if (adapter == null) {
			return;
		}
		boolean empty = adapter.getItemCount() == 0;
		if (empty) {
			tutorial.setVisibility(View.VISIBLE);
		} else {
			tutorial.setVisibility(View.GONE);
		}
	}

	@Override
	public void onStart() {
		super.onStart();
		Intent intent = new Intent(this, PolarisService.class);
		bindService(intent, serviceConnection, 0);
		subscribeToEvents();
	}

	@Override
	public void onStop() {
		super.onStop();
		if (service != null) {
			unbindService(serviceConnection);
			service = null;
		}
		unregisterReceiver(receiver);
		receiver = null;
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.menu_queue, menu);
		updateOrderingIcon();
		return true;
	}

	@Override
	public void onResume() {
		super.onResume();
		if (adapter != null) {
			adapter.notifyDataSetChanged();
		}
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
			case R.id.action_clear:
				clear();
				return true;
			case R.id.action_shuffle:
				shuffle();
				return true;
			case R.id.action_ordering_sequence:
			case R.id.action_ordering_repeat_one:
			case R.id.action_ordering_repeat_all:
				setOrdering(item);
				return true;
			default:
				return super.onOptionsItemSelected(item);
		}
	}

	private void populate() {
		adapter = new QueueAdapter(service);

		RecyclerView recyclerView = (RecyclerView) findViewById(R.id.queue_recycler_view);
		recyclerView.setHasFixedSize(true);
		recyclerView.setLayoutManager(new LinearLayoutManager(this));

		ItemTouchHelper.Callback callback = new QueueTouchCallback(adapter);
		ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
		itemTouchHelper.attachToRecyclerView(recyclerView);

		recyclerView.setAdapter(adapter);
	}

	private void clear() {
		if (service == null) {
			return;
		}
		int oldCount = adapter.getItemCount();
		service.clear();
		adapter.notifyItemRangeRemoved(0, oldCount);
	}

	private void shuffle() {
		if (service == null) {
			return;
		}
		Random rng = new Random();
		int count = adapter.getItemCount();
		for (int i = 0; i <= count - 2; i++) {
			int j = i + rng.nextInt(count - i);
			service.move(i, j);
			adapter.notifyItemMoved(i, j);
		}
	}

	private void setOrdering(MenuItem item) {
		if (service == null) {
			return;
		}
		switch (item.getItemId()) {
			case R.id.action_ordering_sequence:
				service.setOrdering(PlaybackQueue.Ordering.SEQUENCE);
				break;
			case R.id.action_ordering_repeat_one:
				service.setOrdering(PlaybackQueue.Ordering.REPEAT_ONE);
				break;
			case R.id.action_ordering_repeat_all:
				service.setOrdering(PlaybackQueue.Ordering.REPEAT_ALL);
				break;
		}
		updateOrderingIcon();
	}

	private int getIconForOrdering(PlaybackQueue.Ordering ordering) {
		switch (ordering) {
			case REPEAT_ONE:
				return R.drawable.ic_repeat_one_white_24dp;
			case REPEAT_ALL:
				return R.drawable.ic_repeat_white_24dp;
			case SEQUENCE:
			default:
				return R.drawable.ic_reorder_white_24dp;
		}
	}

	private void updateOrderingIcon() {
		if (service == null) {
			return;
		}
		int icon = getIconForOrdering(service.getOrdering());
		MenuItem orderingItem = toolbar.getMenu().findItem(R.id.action_ordering);
		if (orderingItem != null) {
			orderingItem.setIcon(icon);
		}
	}
}
