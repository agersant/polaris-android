package agersant.polaris.features.player;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.ImageView;
import android.widget.SeekBar;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisPlayer;
import agersant.polaris.PolarisState;
import agersant.polaris.R;
import agersant.polaris.api.API;
import agersant.polaris.features.PolarisActivity;

public class PlayerActivity extends PolarisActivity {

	private boolean seeking = false;
	private BroadcastReceiver receiver;
	private ImageView artwork;
	private ImageView pauseToggle;
	private ImageView skipNext;
	private ImageView skipPrevious;
	private SeekBar seekBar;
	private Handler seekBarUpdateHandler;
	private Runnable updateSeekBar;
	private TextView buffering;
	private API api;
	private PolarisPlayer player;
	private PlaybackQueue playbackQueue;

	public PlayerActivity() {
		super(R.string.now_playing, R.id.nav_now_playing);
	}

	@Override
	public void onResume() {
		super.onResume();
		updateContent();
		updateControls();
	}

	private void subscribeToEvents() {
		final PlayerActivity that = this;
		IntentFilter filter = new IntentFilter();
		filter.addAction(PolarisPlayer.PLAYING_TRACK);
		filter.addAction(PolarisPlayer.PAUSED_TRACK);
		filter.addAction(PolarisPlayer.RESUMED_TRACK);
		filter.addAction(PolarisPlayer.COMPLETED_TRACK);
		filter.addAction(PolarisPlayer.OPENING_TRACK);
		filter.addAction(PolarisPlayer.BUFFERING);
		filter.addAction(PolarisPlayer.NOT_BUFFERING);
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
					case PolarisPlayer.OPENING_TRACK:
					case PolarisPlayer.BUFFERING:
					case PolarisPlayer.NOT_BUFFERING:
						that.updateBuffering();
					case PolarisPlayer.PLAYING_TRACK:
						that.updateContent();
						that.updateControls();
						break;
					case PolarisPlayer.PAUSED_TRACK:
					case PolarisPlayer.RESUMED_TRACK:
					case PolarisPlayer.COMPLETED_TRACK:
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
		updateSeekBar = () -> {
			if (!seeking) {
				int precision = 10000;
				float position = player.getPositionRelative();
				seekBar.setMax(precision);
				seekBar.setProgress((int)(precision * position));
			}
			seekBarUpdateHandler.postDelayed(updateSeekBar, 20/*ms*/);
		};
		seekBarUpdateHandler.post(updateSeekBar);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {

		PolarisState state = PolarisApplication.getState();
		api = state.api;
		player = state.player;
		playbackQueue = state.playbackQueue;
		seekBarUpdateHandler = new Handler();

		setContentView(R.layout.activity_player);
		super.onCreate(savedInstanceState);
		artwork = findViewById(R.id.artwork);
		pauseToggle = findViewById(R.id.pause_toggle);
		skipNext = findViewById(R.id.skip_next);
		skipPrevious = findViewById(R.id.skip_previous);
		seekBar = findViewById(R.id.seek_bar);
		buffering = findViewById(R.id.buffering);

		seekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			int newPosition = 0;

			public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
				newPosition = progress;
			}

			public void onStartTrackingTouch(SeekBar seekBar) {
				seeking = true;
			}

			public void onStopTrackingTouch(SeekBar seekBar) {
				player.seekToRelative((float) newPosition / seekBar.getMax());
				seeking = false;
				updateControls();
			}
		});

		updateContent();
		updateControls();
		updateBuffering();
	}

	@Override
	public void onStart() {
		subscribeToEvents();
		scheduleSeekBarUpdates();
		super.onStart();
	}

	@Override
	public void onStop() {
		unregisterReceiver(receiver);
		receiver = null;
		super.onStop();
	}

	@SuppressWarnings("UnusedParameters")
	public void skipPrevious(View view) {
		player.skipPrevious();
	}

	@SuppressWarnings("UnusedParameters")
	public void skipNext(View view) {
		player.skipNext();
	}

	private void updateContent() {
		CollectionItem currentItem = player.getCurrentItem();
		if (currentItem != null) {
			populateWithTrack(currentItem);
		}
	}

	private void updateControls() {
		final float disabledAlpha = 0.2f;

		int playPauseIcon = player.isPlaying() ? R.drawable.ic_pause_black_24dp : R.drawable.ic_play_arrow_black_24dp;
		pauseToggle.setImageResource(playPauseIcon);
		pauseToggle.setAlpha(player.isIdle() ? disabledAlpha : 1.f);

		if (playbackQueue.hasNextTrack(player.getCurrentItem())) {
			skipNext.setClickable(true);
			skipNext.setAlpha(1.0f);
		} else {
			skipNext.setClickable(false);
			skipNext.setAlpha(disabledAlpha);
		}

		if (playbackQueue.hasPreviousTrack(player.getCurrentItem())) {
			skipPrevious.setClickable(true);
			skipPrevious.setAlpha(1.0f);
		} else {
			skipPrevious.setClickable(false);
			skipPrevious.setAlpha(disabledAlpha);
		}
	}

	private void updateBuffering() {
		if (player.isOpeningSong()) {
			buffering.setText(R.string.player_opening);
		} else if (player.isBuffering()) {
			buffering.setText(R.string.player_buffering);
		}
		if (player.isOpeningSong() || player.isBuffering()) {
			buffering.setVisibility(View.VISIBLE);
		} else {
			buffering.setVisibility(View.INVISIBLE);
		}

	}

	private void populateWithTrack(CollectionItem item) {
		assert item != null;

		String title = item.getTitle();
		if (title != null) {
			toolbar.setTitle(title);
		}

		String artist = item.getArtist();
		if (artist != null) {
			toolbar.setSubtitle(artist);
		}

		String artworkPath = item.getArtwork();
		if (artworkPath != null) {
			api.loadImageIntoView(item, artwork);
		}
	}

	@SuppressWarnings("UnusedParameters")
	public void togglePause(View view) {
		if (player.isPlaying()) {
			player.pause();
		} else {
			player.resume();
		}
	}
}
