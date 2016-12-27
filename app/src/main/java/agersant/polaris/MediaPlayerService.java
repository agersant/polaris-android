package agersant.polaris;

import android.app.Service;
import android.content.Intent;
import android.media.MediaDataSource;
import android.media.MediaPlayer;
import android.os.Binder;
import android.os.IBinder;

import agersant.polaris.api.API;

public class MediaPlayerService
		extends Service
		implements MediaPlayer.OnCompletionListener {

	private final IBinder binder = new MediaPlayerBinder();
	private PolarisMediaPlayer player;

	public MediaPlayerService() {
	}

	public void play(CollectionItem item) {
		System.out.println("Beginning playback for: " + item.getPath());
		player.reset();
		try {
			API api = API.getInstance();
			// TODO close old media
			MediaDataSource media = api.getAudio(item);
			player.setDataSource(media);
			player.prepareAsync();
		} catch (Exception e) {
			// TODO Handle
			System.out.println("Error while beginning media playback: " + e);
			return;
		}
		broadcast(Player.PLAYING_TRACK);
	}

	public void resume() {
		player.resume();
		broadcast(Player.RESUMED_TRACK);
	}

	public void pause() {
		player.pause();
		broadcast(Player.PAUSED_TRACK);
	}

	public boolean isPlaying() {
		return player.isPlaying();
	}

	public void seekTo(float progress) {
		player.seekTo(progress);
	}

	public float getProgress() {
		return player.getProgress();
	}

	private void broadcast(String event) {
		Intent intent = new Intent();
		intent.setAction(event);
		sendBroadcast(intent);
	}

	@Override
	public void onCreate() {
		super.onCreate();
		player = new PolarisMediaPlayer();
		player.setOnCompletionListener(this);
	}

	@Override
	public IBinder onBind(Intent intent) {
		return binder;
	}

	@Override
	public void onCompletion(MediaPlayer mp) {
		broadcast(Player.COMPLETED_TRACK);
		PlaybackQueue queue = PlaybackQueue.getInstance(this);
		queue.skipNext();
	}

	public class MediaPlayerBinder extends Binder {
		MediaPlayerService getService() {
			return MediaPlayerService.this;
		}
	}
}
