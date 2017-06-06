package agersant.polaris.features.queue;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
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
import agersant.polaris.R;
import agersant.polaris.api.local.OfflineCache;
import agersant.polaris.api.remote.DownloadQueue;
import agersant.polaris.features.PolarisActivity;

public class QueueActivity extends PolarisActivity {

	private QueueAdapter adapter;
	private BroadcastReceiver receiver;
	private View tutorial;

	public QueueActivity() {
		super(R.string.queue, R.id.nav_queue);
	}

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
						adapter.notifyDataSetChanged();
						break;
				}
			}
		};
		registerReceiver(receiver, filter);
	}

	void updateTutorial() {
		boolean empty = adapter.getItemCount() == 0;
		if (empty) {
			tutorial.setVisibility(View.VISIBLE);
		} else {
			tutorial.setVisibility(View.GONE);
		}
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {

		setContentView(R.layout.activity_queue);
		super.onCreate(savedInstanceState);

		adapter = new QueueAdapter(PlaybackQueue.getInstance());

		RecyclerView recyclerView = (RecyclerView) findViewById(R.id.queue_recycler_view);
		recyclerView.setHasFixedSize(true);
		recyclerView.setLayoutManager(new LinearLayoutManager(this));
		recyclerView.setAdapter(adapter);

		ItemTouchHelper.Callback callback = new QueueTouchCallback(adapter);
		ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
		itemTouchHelper.attachToRecyclerView(recyclerView);

		tutorial = findViewById(R.id.queue_tutorial);
		updateTutorial();
	}

	@Override
	public void onStart() {
		subscribeToEvents();
		super.onStart();
	}

	@Override
	public void onStop() {
		unregisterReceiver(receiver);
		receiver = null;
		super.onStop();
	}

	@Override
	public void onResume() {
		super.onResume();
		adapter.notifyDataSetChanged();
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.menu_queue, menu);
		updateOrderingIcon();
		return true;
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

	private void clear() {
		PlaybackQueue queue = PlaybackQueue.getInstance();
		int oldCount = adapter.getItemCount();
		queue.clear();
		adapter.notifyItemRangeRemoved(0, oldCount);
	}

	private void shuffle() {
		Random rng = new Random();
		PlaybackQueue queue = PlaybackQueue.getInstance();
		int count = adapter.getItemCount();
		for (int i = 0; i <= count - 2; i++) {
			int j = i + rng.nextInt(count - i);
			queue.move(i, j);
			adapter.notifyItemMoved(i, j);
		}
	}

	private void setOrdering(MenuItem item) {
		PlaybackQueue queue = PlaybackQueue.getInstance();
		switch (item.getItemId()) {
			case R.id.action_ordering_sequence:
				queue.setOrdering(PlaybackQueue.Ordering.SEQUENCE);
				break;
			case R.id.action_ordering_repeat_one:
				queue.setOrdering(PlaybackQueue.Ordering.REPEAT_ONE);
				break;
			case R.id.action_ordering_repeat_all:
				queue.setOrdering(PlaybackQueue.Ordering.REPEAT_ALL);
				break;
		}
		updateOrderingIcon();
	}

	private void updateOrderingIcon() {
		PlaybackQueue queue = PlaybackQueue.getInstance();
		int icon = getIconForOrdering(queue.getOrdering());
		MenuItem orderingItem = toolbar.getMenu().findItem(R.id.action_ordering);
		orderingItem.setIcon(icon);
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
}
