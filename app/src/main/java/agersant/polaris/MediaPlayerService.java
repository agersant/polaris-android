package agersant.polaris;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.app.TaskStackBuilder;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.Icon;
import android.media.AudioManager;
import android.media.MediaDataSource;
import android.media.MediaPlayer;
import android.os.Binder;
import android.os.IBinder;
import android.widget.Toast;

import java.io.IOException;

import agersant.polaris.api.API;
import agersant.polaris.features.player.PlayerActivity;

public class MediaPlayerService
		extends Service
		implements MediaPlayer.OnCompletionListener, MediaPlayer.OnErrorListener {

	private final int MEDIA_NOTIFICATION = 1;
	private final String MEDIA_INTENT_PAUSE = "MEDIA_INTENT_PAUSE";
	private final String MEDIA_INTENT_PLAY = "MEDIA_INTENT_PLAY";
	private final String MEDIA_INTENT_SKIP_NEXT = "MEDIA_INTENT_SKIP_NEXT";
	private final String MEDIA_INTENT_SKIP_PREVIOUS = "MEDIA_INTENT_SKIP_PREVIOUS";

	private final IBinder binder = new MediaPlayerBinder();
	private PolarisMediaPlayer player;
	private final BroadcastReceiver receiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			String action = intent.getAction();
			if (action.equals(AudioManager.ACTION_AUDIO_BECOMING_NOISY)) {
				pause();
			}
		}
	};
	private MediaDataSource media;
	private CollectionItem item;

	public void stop() {
		if (player != null) {
			player.release();
			player = null;
		}
		if (media != null) {
			try {
				media.close();
			} catch (IOException e) {
				System.out.println("Error while closing media datasource: " + e);
			}
			media = null;
		}
		item = null;
	}

	public void play(CollectionItem item) {
		System.out.println("Beginning playback for: " + item.getPath());
		stop();

		player = new PolarisMediaPlayer();
		player.setOnCompletionListener(this);
		player.setOnErrorListener(this);

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
		this.item = item;
		pushSystemNotification();
		broadcast(Player.PLAYING_TRACK);
	}

	public boolean isUsing(MediaDataSource media) {
		return this.media == media;
	}

	public void resume() {
		if (player == null) {
			return;
		}
		player.resume();
		broadcast(Player.RESUMED_TRACK);
		pushSystemNotification();
	}

	public void pause() {
		if (player == null) {
			return;
		}
		player.pause();
		broadcast(Player.PAUSED_TRACK);
		pushSystemNotification();
	}

	public boolean isPlaying() {
		if (player == null) {
			return false;
		}
		return player.isPlaying();
	}

	public void seekTo(float progress) {
		if (player != null) {
			player.seekTo(progress);
		}
	}

	public float getProgress() {
		if (player == null) {
			return 0.f;
		}
		return player.getProgress();
	}

	private void broadcast(String event) {
		Intent intent = new Intent();
		intent.setAction(event);
		sendBroadcast(intent);
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		handleIntent(intent);
		return super.onStartCommand(intent, flags, startId);
	}

	@Override
	public void onCreate() {
		super.onCreate();
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
		pushSystemNotification();
		PlaybackQueue queue = PlaybackQueue.getInstance();
		queue.skipNext();
	}

	@Override
	public boolean onError(MediaPlayer mediaPlayer, int i, int i1) {
		displayError();
		return false;
	}

	private void handleIntent(Intent intent) {
		if (intent == null || intent.getAction() == null) {
			return;
		}
		String action = intent.getAction();
		switch (action) {
			case MEDIA_INTENT_PAUSE:
				pause();
				break;
			case MEDIA_INTENT_PLAY:
				resume();
				break;
			case MEDIA_INTENT_SKIP_NEXT:
				PlaybackQueue.getInstance().skipNext();
				break;
			case MEDIA_INTENT_SKIP_PREVIOUS:
				PlaybackQueue.getInstance().skipPrevious();
				break;
		}
	}

	private void displayError() {
		Toast toast = Toast.makeText(this, R.string.playback_error, Toast.LENGTH_SHORT);
		toast.show();
	}

	private void pushSystemNotification() {
		boolean isPlaying = isPlaying();

		Intent resultIntent = new Intent(this, PlayerActivity.class);
		TaskStackBuilder stackBuilder = TaskStackBuilder.create(this)
			.addParentStack(PlayerActivity.class)
			.addNextIntent(resultIntent);
		PendingIntent pendingIntent = stackBuilder.getPendingIntent(0, PendingIntent.FLAG_UPDATE_CURRENT);

		Notification.Builder notificationBuilder = new Notification.Builder(this)
				.setShowWhen(false)
				.setSmallIcon(R.drawable.notification_icon)
				.setContentTitle(item.getTitle())
				.setContentText(item.getArtist())
				.setVisibility(Notification.VISIBILITY_PUBLIC)
				.setContentIntent(pendingIntent)
				.setStyle(new Notification.MediaStyle()
						.setShowActionsInCompactView()
				);

		notificationBuilder.addAction(generateAction(R.drawable.ic_skip_previous_black_24dp, R.string.player_next_track, MEDIA_INTENT_SKIP_PREVIOUS));
		if (isPlaying) {
			notificationBuilder.addAction(generateAction(R.drawable.ic_pause_black_24dp, R.string.player_pause, MEDIA_INTENT_PAUSE));
		} else {
			notificationBuilder.addAction(generateAction(R.drawable.ic_play_arrow_black_24dp, R.string.player_play, MEDIA_INTENT_PLAY));
		}
		notificationBuilder.addAction(generateAction(R.drawable.ic_skip_next_black_24dp, R.string.player_previous_track, MEDIA_INTENT_SKIP_NEXT));

		Notification notification = notificationBuilder.build();
		NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
		notificationManager.notify(MEDIA_NOTIFICATION, notification);

		if (isPlaying) {
			startForeground(MEDIA_NOTIFICATION, notification);
		} else {
			stopForeground(false);
		}
	}

	private Notification.Action generateAction(int icon, int text, String intentAction) {
		Intent intent = new Intent(this, MediaPlayerService.class);
		intent.setAction(intentAction);
		PendingIntent pendingIntent = PendingIntent.getService(this, 0, intent, 0);
		return new Notification.Action.Builder(Icon.createWithResource(this, icon), getResources().getString(text), pendingIntent).build();
	}

	class MediaPlayerBinder extends Binder {
		MediaPlayerService getService() {
			return MediaPlayerService.this;
		}
	}
}
