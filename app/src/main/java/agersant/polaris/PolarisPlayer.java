package agersant.polaris;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;

import agersant.polaris.api.API;
import agersant.polaris.api.FetchAudioTask;

public class PolarisPlayer implements Player.EventListener {

	public static final String PLAYBACK_ERROR = "PLAYBACK_ERROR";
	public static final String PLAYING_TRACK = "PLAYING_TRACK";
	public static final String PAUSED_TRACK = "PAUSED_TRACK";
	public static final String RESUMED_TRACK = "RESUMED_TRACK";
	public static final String COMPLETED_TRACK = "COMPLETED_TRACK";
	public static final String OPENING_TRACK = "OPENING_TRACK";
	public static final String BUFFERING = "BUFFERING";
	public static final String NOT_BUFFERING = "NOT_BUFFERING";

	private final API api;
	private final PlaybackQueue playbackQueue;
	private final ExoPlayer mediaPlayer;
	private MediaSource mediaSource;
	private CollectionItem item;
	private float resumeProgress;
	private FetchAudioTask fetchAudioTask;

	PolarisPlayer(Context context, API api, PlaybackQueue playbackQueue) {
		this.api = api;
		this.playbackQueue = playbackQueue;
		resumeProgress = -1.f;
		mediaPlayer = ExoPlayerFactory.newSimpleInstance(context, new DefaultTrackSelector());
		mediaPlayer.addListener(this);

		IntentFilter filter = new IntentFilter();
		filter.addAction(PlaybackQueue.NO_LONGER_EMPTY);
		BroadcastReceiver receiver = new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				switch (intent.getAction()) {
					case PlaybackQueue.NO_LONGER_EMPTY:
						if (isIdle() || !isPlaying())
						{
							skipNext();
						}
						break;
				}
			}
		};
		context.registerReceiver(receiver, filter);
	}

	private void startServices()
	{
		Context context = PolarisApplication.getInstance();
		context.startService(new Intent(context, PolarisPlaybackService.class));
		context.startService(new Intent(context, PolarisDownloadService.class));
	}

	private void broadcast(String event) {
		PolarisApplication application = PolarisApplication.getInstance();
		Intent intent = new Intent();
		intent.setAction(event);
		application.sendBroadcast(intent);
	}

	private void stop() {
		if (fetchAudioTask != null) {
			fetchAudioTask.cancel(true);
		}
		mediaPlayer.stop();
		seekToRelative(0);
		resumeProgress = -1.f;
		mediaSource = null;
		item = null;
	}

	public void play(CollectionItem item) {

		resumeProgress = -1.f;

		if (this.item != null && item.getPath().equals(this.item.getPath())) {
			System.out.println("Restarting playback for: " + item.getPath());
			seekToRelative(0);
			resume();
			return;
		}

		System.out.println("Beginning playback for: " + item.getPath());
		stop();

		fetchAudioTask = api.loadAudio(item, (MediaSource fetchedMediaSource) -> {
			fetchAudioTask = null;
			if (fetchedMediaSource != null) {
				try {
					mediaSource = fetchedMediaSource;
					mediaPlayer.prepare(mediaSource);
					broadcast(PLAYING_TRACK);
				} catch (Exception e) {
					System.out.println("Error while beginning media playback: " + e);
					broadcast(PLAYBACK_ERROR);
				}
			} else {
				System.out.println("Could not find audio for");
			}
		});

		mediaPlayer.setPlayWhenReady(true);
		this.item = item;
		broadcast(OPENING_TRACK);
		startServices();
	}

	public CollectionItem getCurrentItem() {
		return item;
	}

	public boolean isUsing(MediaSource mediaSource) {
		return this.mediaSource == mediaSource;
	}

	public void resume() {
		mediaPlayer.setPlayWhenReady(true);
		broadcast(PolarisPlayer.RESUMED_TRACK);
		startServices();
	}

	public void pause() {
		mediaPlayer.setPlayWhenReady(false);
		broadcast(PolarisPlayer.PAUSED_TRACK);
	}

	private boolean advance(CollectionItem currentItem, int delta) {
		CollectionItem newTrack = playbackQueue.getNextTrack(currentItem, delta);
		if (newTrack != null) {
			play(newTrack);
			return true;
		}
		return false;
	}

	public void skipPrevious() {
		CollectionItem currentItem = getCurrentItem();
		advance(currentItem, -1);
	}

	public boolean skipNext() {
		CollectionItem currentItem = getCurrentItem();
		return advance(currentItem, 1);
	}

	public boolean isIdle() {
		return getCurrentItem() == null;
	}

	public boolean isOpeningSong() {
		return fetchAudioTask != null;
	}

	public boolean isPlaying() {
		return mediaPlayer.getPlayWhenReady();
	}

	public boolean isBuffering() {
		return mediaPlayer.getPlaybackState() == ExoPlayer.STATE_BUFFERING;
	}

	public void seekToRelative(float progress) {
		resumeProgress = -1;

		if (progress == 0.f) {
			mediaPlayer.seekTo(0);
			return;
		}

		long duration = mediaPlayer.getDuration();
		if (duration == C.TIME_UNSET) {
			resumeProgress = progress;
			return;
		}

		long position = (long)( duration * progress );
		mediaPlayer.seekTo(position);
	}

	public float getPositionRelative() {
		if (resumeProgress >= 0) {
			return resumeProgress;
		}
		long position = mediaPlayer.getCurrentPosition();
		if (position == C.TIME_UNSET) {
			return 0.f;
		}
		long duration = mediaPlayer.getDuration();
		if (duration == C.TIME_UNSET) {
			return 0.f;
		}
		return (float) position / duration;
	}

	@Override
	public void onTracksChanged(TrackGroupArray trackGroups, TrackSelectionArray trackSelections) {
	}

	@Override
	public void onLoadingChanged(boolean isLoading) {
	}

	@Override
	public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
		if (playbackState == Player.STATE_BUFFERING) {
			broadcast(BUFFERING);
		} else {
			broadcast(NOT_BUFFERING);
		}

		switch (playbackState) {
			case Player.STATE_READY:
				if (resumeProgress > 0.f) {
					seekToRelative(resumeProgress);
				}
				break;
			case Player.STATE_ENDED:
				broadcast(COMPLETED_TRACK);
				if (!skipNext()) {
					pause();
					seekToRelative(0);
				}
				break;
		}
	}

	@Override
	public void onPlayerError(ExoPlaybackException error) {
		broadcast(PLAYBACK_ERROR);
	}

	@Override
	public void onPlaybackParametersChanged(PlaybackParameters playbackParameters) {
	}
}
