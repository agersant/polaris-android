package agersant.polaris.features.player;

import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.view.View;
import android.widget.ImageView;
import android.widget.SeekBar;

import java.util.Timer;
import java.util.TimerTask;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.Player;
import agersant.polaris.PolarisService;
import agersant.polaris.R;
import agersant.polaris.features.PolarisActivity;

public class PlayerActivity extends PolarisActivity {

	boolean seeking = false;
	private Timer timer;
	private BroadcastReceiver receiver;
	private ImageView artwork;
	private ImageView pauseToggle;
	private ImageView skipNext;
	private ImageView skipPrevious;
	private SeekBar seekBar;
	private PolarisService service;

	public PlayerActivity() {
		super(R.string.now_playing, R.id.nav_now_playing);
	}
	private ServiceConnection serviceConnection = new ServiceConnection() {
		@Override
		public void onServiceDisconnected(ComponentName name) {
			service = null;
		}

		@Override
		public void onServiceConnected(ComponentName name, IBinder iBinder) {
			service = ((PolarisService.PolarisBinder) iBinder).getService();
			updateContent();
			updateControls();
		}
	};

	@Override
	public void onResume() {
		super.onResume();
		updateContent();
		updateControls();
	}

	private void subscribeToEvents() {
		final PlayerActivity that = this;
		IntentFilter filter = new IntentFilter();
		filter.addAction(Player.PLAYING_TRACK);
		filter.addAction(Player.PAUSED_TRACK);
		filter.addAction(Player.RESUMED_TRACK);
		filter.addAction(Player.COMPLETED_TRACK);
		filter.addAction(PlaybackQueue.CHANGED_ORDERING);
		filter.addAction(PlaybackQueue.QUEUED_ITEM);
		filter.addAction(PlaybackQueue.QUEUED_ITEMS);
		filter.addAction(PlaybackQueue.REMOVED_ITEM);
		filter.addAction(PlaybackQueue.REMOVED_ITEMS);
		filter.addAction(PlaybackQueue.REORDERED_ITEMS);
		receiver = new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				switch (intent.getAction()) {
					case Player.PLAYING_TRACK:
						that.updateContent();
						that.updateControls();
						break;
					case Player.PAUSED_TRACK:
					case Player.RESUMED_TRACK:
					case Player.COMPLETED_TRACK:
					case PlaybackQueue.CHANGED_ORDERING:
					case PlaybackQueue.REMOVED_ITEM:
					case PlaybackQueue.REMOVED_ITEMS:
					case PlaybackQueue.REORDERED_ITEMS:
					case PlaybackQueue.QUEUED_ITEM:
					case PlaybackQueue.QUEUED_ITEMS:
						that.updateControls();
						break;
				}
			}
		};
		registerReceiver(receiver, filter);
	}

	private void scheduleSeekBarUpdates() {
		timer = new Timer();
		timer.schedule(new TimerTask() {
			@Override
			public void run() {
				if (!seeking) {
					updateSeekBar();
				}
			}
		}, 0, 20); // in ms
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		setContentView(R.layout.activity_player);
		super.onCreate(savedInstanceState);
		artwork = (ImageView) findViewById(R.id.artwork);
		pauseToggle = (ImageView) findViewById(R.id.pause_toggle);
		skipNext = (ImageView) findViewById(R.id.skip_next);
		skipPrevious = (ImageView) findViewById(R.id.skip_previous);
		seekBar = (SeekBar) findViewById(R.id.seek_bar);

		seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			int newPosition = 0;

			public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
				newPosition = progress;
			}

			public void onStartTrackingTouch(SeekBar seekBar) {
				seeking = true;
			}

			public void onStopTrackingTouch(SeekBar seekBar) {
				if (service != null) {
					service.seekToRelative((float) newPosition / seekBar.getMax());
				}
				seeking = false;
				updateControls();
			}
		});
	}

	@Override
	public void onStart() {
		Intent intent = new Intent(this, PolarisService.class);
		bindService(intent, serviceConnection, 0);

		subscribeToEvents();
		scheduleSeekBarUpdates();
		super.onStart();
	}

	@Override
	public void onStop() {
		if (service != null) {
			unbindService(serviceConnection);
		}
		unregisterReceiver(receiver);
		receiver = null;
		timer.cancel();
		timer = null;
		super.onStop();
	}

	public void skipPrevious(View view) {
		service.skipPrevious();
	}

	public void skipNext(View view) {
		service.skipNext();
	}

	private void updateContent() {
		if (service == null) {
			return;
		}
		CollectionItem currentItem = service.getCurrentItem();
		if (currentItem != null) {
			populateWithTrack(currentItem);
		}
	}

	private void updateControls() {

		if (service == null) {
			return;
		}
		final float disabledAlpha = 0.2f;

		int playPauseIcon = service.isPlaying() ? R.drawable.ic_pause_black_24dp : R.drawable.ic_play_arrow_black_24dp;
		pauseToggle.setImageResource(playPauseIcon);
		pauseToggle.setAlpha(service.isIdle() ? disabledAlpha : 1.f);

		if (service.hasNextTrack()) {
			skipNext.setClickable(true);
			skipNext.setAlpha(1.0f);
		} else {
			skipNext.setClickable(false);
			skipNext.setAlpha(disabledAlpha);
		}

		if (service.hasPreviousTrack()) {
			skipPrevious.setClickable(true);
			skipPrevious.setAlpha(1.0f);
		} else {
			skipPrevious.setClickable(false);
			skipPrevious.setAlpha(disabledAlpha);
		}
	}

	private void updateSeekBar() {
		if (service == null) {
			return;
		}
		int duration = (int) service.getDuration();
		seekBar.setMax(duration);
		int position = (int) service.getPosition();
		seekBar.setProgress(position);
	}

	private void populateWithTrack(CollectionItem item) {
		if (service == null) {
			return;
		}

		assert item != null;

		String title = item.getTitle();
		if (title != null) {
			toolbar.setTitle(title);
		}

		String artist = item.getArtist();
		if (artist != null) {
			toolbar.setSubtitle(artist);
		}

		service.getAPI().getImage(item, artwork);
	}

	public void togglePause(View view) {
		if (service == null) {
			return;
		}
		if (service.isPlaying()) {
			service.pause();
		} else {
			service.resume();
		}
	}
}
