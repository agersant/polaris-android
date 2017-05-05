package agersant.polaris;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;
import android.media.MediaDataSource;
import android.media.MediaPlayer;
import android.os.Binder;
import android.os.IBinder;
import android.widget.Toast;

import java.io.IOException;

import agersant.polaris.api.API;

public class MediaPlayerService
		extends Service
		implements MediaPlayer.OnCompletionListener, MediaPlayer.OnErrorListener {

	private final IBinder binder = new MediaPlayerBinder();
	private PolarisMediaPlayer player;
	private MediaDataSource media;

	public void stop() {
		player.reset();
		if (media != null) {
			try {
				media.close();
			} catch (IOException e) {
				System.out.println("Error while closing media datasource: " + e);
			}
			media = null;
		}
	}

	public void play(CollectionItem item) {
		System.out.println("Beginning playback for: " + item.getPath());
		stop();
		try {
			API api = API.getInstance();
			media = api.getAudio(item);
			player.setDataSource(media);
			player.prepareAsync();
		} catch (Exception e) {
			System.out.println("Error while beginning media playback: " + e);
			displayError();
			return;
		}
		broadcast(Player.PLAYING_TRACK);
	}

	public boolean isUsing(MediaDataSource media) {
		return this.media == media;
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
		player.setOnErrorListener(this);
		registerReceiver(receiver, new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY));
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		unregisterReceiver(receiver);
	}

	@Override
	public IBinder onBind(Intent intent) {
		return binder;
	}

	@Override
	public void onCompletion(MediaPlayer mp) {
		broadcast(Player.COMPLETED_TRACK);
		PlaybackQueue queue = PlaybackQueue.getInstance();
		queue.skipNext();
	}

	@Override
	public boolean onError(MediaPlayer mediaPlayer, int i, int i1) {
		displayError();
		return false;
	}

	private void displayError() {
		Toast toast = Toast.makeText(this, R.string.playback_error, Toast.LENGTH_SHORT);
		toast.show();
	}

	class MediaPlayerBinder extends Binder {
		MediaPlayerService getService() {
			return MediaPlayerService.this;
		}
	}

	private final BroadcastReceiver receiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			String action = intent.getAction();
			if (action.equals(AudioManager.ACTION_AUDIO_BECOMING_NOISY)) {
				pause();
			}
		}
	};
}
