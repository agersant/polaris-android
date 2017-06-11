package agersant.polaris;

import android.content.Intent;
import android.media.MediaDataSource;
import android.media.MediaPlayer;

import java.io.IOException;

public class Player implements MediaPlayer.OnCompletionListener, MediaPlayer.OnErrorListener {

	public static final String PLAYBACK_ERROR = "PLAYBACK_ERROR";
	public static final String PLAYING_TRACK = "PLAYING_TRACK";
	public static final String PAUSED_TRACK = "PAUSED_TRACK";
	public static final String RESUMED_TRACK = "RESUMED_TRACK";
	public static final String COMPLETED_TRACK = "COMPLETED_TRACK";

	private PolarisMediaPlayer mediaPlayer;
	private MediaDataSource media;
	private CollectionItem item;
	private PolarisService service;

	Player(PolarisService service) {
		this.service = service;
	}

	private void broadcast(String event) {
		PolarisApplication application = PolarisApplication.getInstance();
		Intent intent = new Intent();
		intent.setAction(event);
		application.sendBroadcast(intent);
	}

	void stop() {
		if (mediaPlayer != null) {
			mediaPlayer.release();
			mediaPlayer = null;
		}
		if (media != null) {
			try {
				media.close();
			} catch (IOException e) {
				System.out.println("Error while closing media datasource: " + e);
			}
			media = null;
		}
	}

	void play(CollectionItem item) {
		System.out.println("Beginning playback for: " + item.getPath());
		stop();

		mediaPlayer = new PolarisMediaPlayer();
		mediaPlayer.setOnCompletionListener(this);
		mediaPlayer.setOnErrorListener(this);

		try {
			media = service.getAPI().getAudio(item);
			mediaPlayer.setDataSource(media);
			mediaPlayer.prepareAsync();
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

	boolean isUsing(MediaDataSource media) {
		return this.media == media;
	}

	void resume() {
		if (mediaPlayer == null) {
			return;
		}
		mediaPlayer.resume();
		broadcast(Player.RESUMED_TRACK);
	}

	void pause() {
		if (mediaPlayer == null) {
			return;
		}
		mediaPlayer.pause();
		broadcast(Player.PAUSED_TRACK);
	}

	boolean isPlaying() {
		if (mediaPlayer == null) {
			return false;
		}
		return mediaPlayer.isPlaying();
	}

	void seekTo(float progress) {
		if (mediaPlayer != null) {
			mediaPlayer.seekTo(progress);
		}
	}

	float getProgress() {
		if (mediaPlayer == null) {
			return 0.f;
		}
		return mediaPlayer.getProgress();
	}

	@Override
	public void onCompletion(MediaPlayer mp) {
		broadcast(COMPLETED_TRACK);
	}

	@Override
	public boolean onError(MediaPlayer mediaPlayer, int i, int i1) {
		broadcast(PLAYBACK_ERROR);
		return false;
	}

}
