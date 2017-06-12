package agersant.polaris;

import android.content.Intent;
import android.net.Uri;

import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.Timeline;
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory;
import com.google.android.exoplayer2.source.ExtractorMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;

import java.io.File;

import agersant.polaris.api.remote.PolarisExoPlayerDataSourceFactory;

public class Player implements ExoPlayer.EventListener {

	public static final String PLAYBACK_ERROR = "PLAYBACK_ERROR";
	public static final String PLAYING_TRACK = "PLAYING_TRACK";
	public static final String PAUSED_TRACK = "PAUSED_TRACK";
	public static final String RESUMED_TRACK = "RESUMED_TRACK";
	public static final String COMPLETED_TRACK = "COMPLETED_TRACK";

	private ExoPlayer mediaPlayer;
	private Uri currentURI;
	private CollectionItem item;
	private PolarisService service;
	private float resumeProgress;

	Player(PolarisService service) {
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

	void stop() {
		mediaPlayer.stop();
		resumeProgress = -1.f;
		item = null;
	}

	void play(CollectionItem item) {

		resumeProgress = -1.f;

		if (this.item != null && item.getPath().equals(this.item.getPath())) {
			System.out.println("Restarting playback for: " + item.getPath());
			seekTo(0);
			resume();
			return;
		}

		System.out.println("Beginning playback for: " + item.getPath());
		stop();

		try {
			currentURI = service.getAPI().getAudio(item);
			PolarisExoPlayerDataSourceFactory dsf = new PolarisExoPlayerDataSourceFactory(service);
			MediaSource mediaSource = new ExtractorMediaSource(currentURI, dsf, new DefaultExtractorsFactory(), null, null);
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

	boolean isIdle() {
		return item == null;
	}

	boolean isUsing(File file) {
		// TODO
		return false;
	}

	void resume() {
		mediaPlayer.setPlayWhenReady(true);
		broadcast(Player.RESUMED_TRACK);
	}

	void pause() {
		mediaPlayer.setPlayWhenReady(false);
		broadcast(Player.PAUSED_TRACK);
	}

	boolean isPlaying() {
		return mediaPlayer.getPlayWhenReady();
	}

	void seekTo(float progress) {
		long duration = mediaPlayer.getDuration();
		if (duration == C.TIME_UNSET) {
			resumeProgress = progress;
			return;
		}
		resumeProgress = -1;
		long position = (long)( duration * progress );
		mediaPlayer.seekTo(position);
	}

	long getDuration() {
		long duration = mediaPlayer.getDuration();
		if (duration == C.TIME_UNSET) {
			return 0;
		}
		return duration;
	}

	long getPosition() {
		long position = mediaPlayer.getCurrentPosition();
		if (position == C.TIME_UNSET) {
			return 0;
		}
		return position;
	}

	@Override
	public void onTimelineChanged(Timeline timeline, Object manifest) {
	}

	@Override
	public void onTracksChanged(TrackGroupArray trackGroups, TrackSelectionArray trackSelections) {
	}

	@Override
	public void onLoadingChanged(boolean isLoading) {
	}

	@Override
	public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
		if (playbackState == ExoPlayer.STATE_READY) {
			if (resumeProgress > 0.f) {
				seekTo(resumeProgress);
			}
		}
		if (playbackState == ExoPlayer.STATE_ENDED) {
			broadcast(COMPLETED_TRACK);
		}
	}

	@Override
	public void onPlayerError(ExoPlaybackException error) {
		broadcast(PLAYBACK_ERROR);
	}

	@Override
	public void onPositionDiscontinuity() {
	}

	@Override
	public void onPlaybackParametersChanged(PlaybackParameters playbackParameters) {
	}
}
