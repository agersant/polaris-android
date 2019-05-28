package agersant.polaris;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.app.TaskStackBuilder;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.graphics.drawable.Icon;
import android.media.AudioManager;
import android.os.AsyncTask;
import android.os.Binder;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.widget.Toast;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.lang.ref.WeakReference;
import java.util.ArrayList;

import agersant.polaris.api.API;
import agersant.polaris.features.player.PlayerActivity;


public class PolarisPlaybackService extends Service {

	private static final int MEDIA_NOTIFICATION = 100;
	private static final String MEDIA_INTENT_PAUSE = "MEDIA_INTENT_PAUSE";
	private static final String MEDIA_INTENT_PLAY = "MEDIA_INTENT_PLAY";
	private static final String MEDIA_INTENT_SKIP_NEXT = "MEDIA_INTENT_SKIP_NEXT";
	private static final String MEDIA_INTENT_SKIP_PREVIOUS = "MEDIA_INTENT_SKIP_PREVIOUS";
	private static final String MEDIA_INTENT_DISMISS = "MEDIA_INTENT_DISMISS";
	public static final String APP_INTENT_COLD_BOOT = "POLARIS_PLAYBACK_SERVICE_COLD_BOOT";

	private static final String NOTIFICATION_CHANNEL_ID = "POLARIS_NOTIFICATION_CHANNEL_ID";

	private final IBinder binder = new PolarisPlaybackService.PolarisBinder();
	private BroadcastReceiver receiver;
	private Notification notification;
	private CollectionItem notificationItem;
	private NotificationManager notificationManager;
	private Handler autoSaveHandler;
	private Runnable autoSaveRunnable;

	private Runnable dataUpdateRunnable;
	private Handler dataUpdateHandler;

	private API api;
	private PolarisPlayer player;
	private PlaybackQueue playbackQueue;

	private MediaSessionCompat mediaSession;

	private class Callback extends MediaSessionCompat.Callback {
	    private final PolarisPlayer player;

	    Callback(PolarisPlayer player) {
	        this.player = player;
        }

	    @Override
        public void onPause() {
	        player.pause();
        }

        @Override
        public void onPlay() {
	        player.resume();
        }

        @Override
        public void onSkipToNext() {
	        player.skipNext();
        }

        @Override
        public void onSkipToPrevious() {
	        player.skipPrevious();
        }
    }

	@Override
	public void onCreate() {
		super.onCreate();

		PolarisState state = PolarisApplication.getState();
		api = state.api;
		player = state.player;
		playbackQueue = state.playbackQueue;

		notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
		if (Build.VERSION.SDK_INT > 25 ) {
			NotificationChannel notificationChannel = new NotificationChannel(NOTIFICATION_CHANNEL_ID, getResources().getString(R.string.media_notifications_channel_description), NotificationManager.IMPORTANCE_LOW);
			notificationChannel.setDescription("Notifications for current song playing in Polaris.");
			notificationChannel.enableLights(false);
			notificationChannel.enableVibration(false);
			notificationChannel.setShowBadge(false);
			notificationManager.createNotificationChannel(notificationChannel);
			notificationManager.deleteNotificationChannel(NOTIFICATION_CHANNEL_ID);
			notificationManager.createNotificationChannel(notificationChannel);
		}

		IntentFilter filter = new IntentFilter();
		filter.addAction(AudioManager.ACTION_AUDIO_BECOMING_NOISY);
		filter.addAction(PolarisPlayer.PLAYING_TRACK);
		filter.addAction(PolarisPlayer.PAUSED_TRACK);
		filter.addAction(PolarisPlayer.RESUMED_TRACK);
		filter.addAction(PolarisPlayer.PLAYBACK_ERROR);
		filter.addAction(PolarisPlayer.COMPLETED_TRACK);
		receiver = new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				switch (intent.getAction()) {
					case PolarisPlayer.PLAYBACK_ERROR:
						stopDataUpdates();
						displayError();
						break;
					case PolarisPlayer.PLAYING_TRACK:
					case PolarisPlayer.RESUMED_TRACK:
						startDataUpdates();
						updateMediaSessionState(PlaybackStateCompat.STATE_PLAYING);
						pushSystemNotification();
						break;
					case PolarisPlayer.PAUSED_TRACK:
						stopDataUpdates();
						updateMediaSessionState(PlaybackStateCompat.STATE_PAUSED);
						pushSystemNotification();
						saveStateToDisk();
						break;
					case AudioManager.ACTION_AUDIO_BECOMING_NOISY:
						stopDataUpdates();
						player.pause();
						updateMediaSessionState(PlaybackStateCompat.STATE_PAUSED);
						break;
				}
			}
		};
		registerReceiver(receiver, filter);

		autoSaveRunnable = () -> {
			saveStateToDisk();
			autoSaveHandler.postDelayed(autoSaveRunnable, 5000);
		};
		autoSaveHandler = new Handler();
		autoSaveHandler.postDelayed(autoSaveRunnable, 5000);

		pushSystemNotification();

		mediaSession = new MediaSessionCompat(this, getPackageName());
		mediaSession.setCallback(new Callback(player));
        mediaSession.setActive(true);

		updateMediaSessionState(PlaybackStateCompat.STATE_NONE);

		dataUpdateRunnable = () -> {
			updateMediaSessionState(player.isPlaying() ? PlaybackStateCompat.STATE_PLAYING : PlaybackStateCompat.STATE_PAUSED);
			dataUpdateHandler.postDelayed(dataUpdateRunnable, 5000);
		};
		dataUpdateHandler = new Handler();
		startDataUpdates();

	}

	private void updateMediaSessionState(int state) {
		PlaybackStateCompat.Builder builder = new PlaybackStateCompat.Builder();
		builder.setActions(PlaybackStateCompat.ACTION_PLAY | PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_PAUSE | PlaybackStateCompat.ACTION_SKIP_TO_NEXT | PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS);
		builder.setState(state, (long)player.getCurrentPosition(), 1);
		mediaSession.setPlaybackState(builder.build());

		MediaMetadataCompat.Builder metadataBuilder = new MediaMetadataCompat.Builder();
		if(player.getCurrentItem() != null) {
			metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_TITLE, player.getCurrentItem().getTitle());
			metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, player.getCurrentItem().getArtist());
			metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_ALBUM, player.getCurrentItem().getAlbum());
			metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_ALBUM_ARTIST, player.getCurrentItem().getAlbumArtist());
			metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_TRACK_NUMBER, player.getCurrentItem().getTrackNumber());
			metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_DISC_NUMBER, player.getCurrentItem().getDiscNumber());
		}
		metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_DURATION, (long)player.getDuration());
		mediaSession.setMetadata(metadataBuilder.build());
	}

	@Override
	public void onDestroy() {
	    mediaSession.release();
		unregisterReceiver(receiver);
		autoSaveHandler.removeCallbacksAndMessages(null);
		stopDataUpdates();
		super.onDestroy();
	}

	private void startDataUpdates() {
		stopDataUpdates();
		dataUpdateHandler.postDelayed(dataUpdateRunnable, 5000);
	}

	private void stopDataUpdates() {
		dataUpdateHandler.removeCallbacksAndMessages(null);
	}

	@Override
	public IBinder onBind(Intent intent) {
		return binder;
	}

	private class PolarisBinder extends Binder {	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		handleIntent(intent);
		super.onStartCommand(intent, flags, startId);
		return START_NOT_STICKY;
	}

	// Internals
	private void displayError() {
		Toast toast = Toast.makeText(this, R.string.playback_error, Toast.LENGTH_SHORT);
		toast.show();
	}

	private void handleIntent(Intent intent) {
		if (intent == null || intent.getAction() == null) {
			return;
		}
		String action = intent.getAction();
		switch (action) {
			case APP_INTENT_COLD_BOOT:
				restoreStateFromDisk();
				break;
			case MEDIA_INTENT_PAUSE:
				player.pause();
				break;
			case MEDIA_INTENT_PLAY:
				player.resume();
				break;
			case MEDIA_INTENT_SKIP_NEXT:
				player.skipNext();
				break;
			case MEDIA_INTENT_SKIP_PREVIOUS:
				player.skipPrevious();
				break;
			case MEDIA_INTENT_DISMISS:
				stopSelf();
				break;
		}
	}

	private void pushSystemNotification() {

		boolean isPlaying = player.isPlaying();
		final CollectionItem item = player.getCurrentItem();
		if (item == null) {
			return;
		}

		// On tap action
		TaskStackBuilder stackBuilder = TaskStackBuilder.create(this)
				.addParentStack(PlayerActivity.class)
				.addNextIntent(new Intent(this, PlayerActivity.class));
		PendingIntent tapPendingIntent = stackBuilder.getPendingIntent(0, PendingIntent.FLAG_UPDATE_CURRENT);

		// On dismiss action
		Intent dismissIntent = new Intent(this, PolarisPlaybackService.class);
		dismissIntent.setAction(MEDIA_INTENT_DISMISS);
		PendingIntent dismissPendingIntent = PendingIntent.getService(this, 0, dismissIntent, 0);

		// Create notification
		final Notification.Builder notificationBuilder;
		if (Build.VERSION.SDK_INT > 25 ) {
			notificationBuilder = new Notification.Builder(this, NOTIFICATION_CHANNEL_ID);
		}
		else
		{
			notificationBuilder = new Notification.Builder(this);
		}
		notificationBuilder.setShowWhen(false)
			.setSmallIcon(R.drawable.notification_icon)
			.setContentTitle(item.getTitle())
			.setContentText(item.getArtist())
			.setVisibility(Notification.VISIBILITY_PUBLIC)
			.setContentIntent(tapPendingIntent)
			.setDeleteIntent(dismissPendingIntent)
			.setStyle(new Notification.MediaStyle()
					.setShowActionsInCompactView()
			);

		// Add album art
		if (item == notificationItem && notification != null && notification.getLargeIcon() != null) {
			notificationBuilder.setLargeIcon(notification.getLargeIcon());
		}
		if (item.getArtwork() != null) {
			api.loadImage(item, (Bitmap bitmap) -> {
				if (item != player.getCurrentItem()) {
					return;
				}
				notificationBuilder.setLargeIcon(bitmap);
				emitNotification(notificationBuilder, item);
			});
		}

		// Add media control actions
		notificationBuilder.addAction(generateAction(R.drawable.ic_skip_previous_black_24dp, R.string.player_next_track, MEDIA_INTENT_SKIP_PREVIOUS));
		if (isPlaying) {
			notificationBuilder.addAction(generateAction(R.drawable.ic_pause_black_24dp, R.string.player_pause, MEDIA_INTENT_PAUSE));
		} else {
			notificationBuilder.addAction(generateAction(R.drawable.ic_play_arrow_black_24dp, R.string.player_play, MEDIA_INTENT_PLAY));
		}
		notificationBuilder.addAction(generateAction(R.drawable.ic_skip_next_black_24dp, R.string.player_previous_track, MEDIA_INTENT_SKIP_NEXT));

		// Emit notification
		emitNotification(notificationBuilder, item);

		if (isPlaying) {
			startForeground(MEDIA_NOTIFICATION, notification);
		} else {
			stopForeground(false);
		}
	}

	private void emitNotification(Notification.Builder notificationBuilder, CollectionItem item) {
		notificationItem = item;
		notification = notificationBuilder.build();
		notificationManager.notify(MEDIA_NOTIFICATION, notification);
	}

	private Notification.Action generateAction(int icon, int text, String intentAction) {
		Intent intent = new Intent(this, PolarisPlaybackService.class);
		intent.setAction(intentAction);
		PendingIntent pendingIntent = PendingIntent.getService(this, 0, intent, 0);
		return new Notification.Action.Builder(Icon.createWithResource(this, icon), getResources().getString(text), pendingIntent).build();
	}

	private static class StateWriteTask extends AsyncTask<Void, Void, Void> {

		private final PlaybackQueueState state;
		private final WeakReference<Context> contextWeakReference;

		StateWriteTask(Context context, PlaybackQueueState state) {
			this.contextWeakReference = new WeakReference<>(context);
			this.state = state;
		}

		@Override
		protected Void doInBackground(Void... objects) {
			Context context = contextWeakReference.get();
			if (context == null) {
				return null;
			}
			File storage = new File(context.getCacheDir(), "playlist.v" + PlaybackQueueState.VERSION);

			try (FileOutputStream out = new FileOutputStream(storage)) {
				try (ObjectOutputStream objOut = new ObjectOutputStream(out)) {
					objOut.writeObject(state);
				} catch (IOException e) {
					System.out.println("Error while saving PlaybackQueueState object: " + e);
				}
			} catch (IOException e) {
				System.out.println("Error while writing PlaybackQueueState file: " + e);
			}
			return null;
		}
	}

	private void saveStateToDisk() {
		// Gather state
		PlaybackQueueState state = new PlaybackQueueState();
		state.queueContent = new ArrayList<>();
		for (CollectionItem item : playbackQueue.getContent())
		{
			try {
				state.queueContent.add(item.clone());
			} catch(CloneNotSupportedException e) {
				System.out.println("Error gathering PlaybackQueueState content: " + e);
			}
		}
		state.queueOrdering = playbackQueue.getOrdering();
		CollectionItem currentItem = player.getCurrentItem();
		state.queueIndex = playbackQueue.getContent().indexOf(currentItem);
		state.trackProgress = player.getPositionRelative();

		// Persist
		StateWriteTask writeState = new StateWriteTask(this, state);
		writeState.executeOnExecutor(AsyncTask.SERIAL_EXECUTOR);
	}

	private void restoreStateFromDisk() {
		File storage = new File(getCacheDir(), "playlist.v" + PlaybackQueueState.VERSION);
		try (FileInputStream in = new FileInputStream(storage)) {
			try (ObjectInputStream objIn = new ObjectInputStream(in)) {
				Object obj = objIn.readObject();
				if (obj instanceof PlaybackQueueState) {
					PlaybackQueueState state = (PlaybackQueueState) obj;
					playbackQueue.setContent(state.queueContent);
					playbackQueue.setOrdering(state.queueOrdering);
					if (state.queueIndex >= 0) {
						CollectionItem currentItem = playbackQueue.getItem(state.queueIndex);
						if (currentItem != null) {
							player.play(currentItem);
							player.pause();
							player.seekToRelative(state.trackProgress);
						}
					}
				}
			} catch (ClassNotFoundException e) {
				System.out.println("Error while loading PlaybackQueueState object: " + e);
			}
		} catch (IOException e) {
			System.out.println("Error while reading PlaybackQueueState file: " + e);
		}
	}
}
