package agersant.polaris;

import android.content.Intent;

import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;

public class PolarisPlayer implements Player.EventListener {

	public static final String PLAYBACK_ERROR = "PLAYBACK_ERROR";
	public static final String PLAYING_TRACK = "PLAYING_TRACK";
	public static final String PAUSED_TRACK = "PAUSED_TRACK";
	public static final String RESUMED_TRACK = "RESUMED_TRACK";
	public static final String COMPLETED_TRACK = "COMPLETED_TRACK";
	public static final String BUFFERING = "BUFFERING";
	public static final String NOT_BUFFERING = "NOT_BUFFERING";

	private final PolarisService service;
	private final ExoPlayer mediaPlayer;
	private MediaSource mediaSource;
	private CollectionItem item;
	private float resumeProgress;

	PolarisPlayer(PolarisService service) {
		this.service = service;
		resumeProgress = -1.f;
		mediaPlayer = ExoPlayerFactory.newSimpleInstance(service, new DefaultTrackSelector());
		mediaPlayer.addListener(this);
	}

	private void broadcast(String event) {
		PolarisApplication application = PolarisApplication.getInstance();
		Intent intent = new Intent();
		intent.setAction(event);
		application.sendBroadcast(intent);
	}

	private void stop() {
		mediaPlayer.stop();
		seekToRelative(0);
		resumeProgress = -1.f;
		mediaSource = null;
		item = null;
	}

	void play(CollectionItem item) {

		resumeProgress = -1.f;

		if (this.item != null && item.getPath().equals(this.item.getPath())) {
			System.out.println("Restarting playback for: " + item.getPath());
			seekToRelative(0);
			resume();
			return;
		}

		System.out.println("Beginning playback for: " + item.getPath());
		stop();

		try {
			mediaSource = service.getAPI().getAudio(item);
			mediaPlayer.prepare(mediaSource);
			mediaPlayer.setPlayWhenReady(true);
		} catch (Exception e) {
			System.out.println("Error while beginning media playback: " + e);
			broadcast(PLAYBACK_ERROR);
			return;
		}
		this.item = item;
		broadcast(PLAYING_TRACK);
	}

	CollectionItem getCurrentItem() {
		return item;
	}

	boolean isUsing(MediaSource mediaSource) {
		return this.mediaSource == mediaSource;
	}

	void resume() {
		mediaPlayer.setPlayWhenReady(true);
		broadcast(PolarisPlayer.RESUMED_TRACK);
	}

	void pause() {
		mediaPlayer.setPlayWhenReady(false);
		broadcast(PolarisPlayer.PAUSED_TRACK);
	}

	boolean isPlaying() {
		return mediaPlayer.getPlayWhenReady();
	}

	boolean isBuffering() {
		return mediaPlayer.getPlaybackState() == ExoPlayer.STATE_BUFFERING;
	}

	void seekToRelative(float progress) {
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

	float getPositionRelative() {
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
