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
import android.graphics.drawable.Icon;
import android.media.AudioManager;
import android.os.Binder;
import android.os.IBinder;
import android.widget.Toast;

import com.google.android.exoplayer2.source.MediaSource;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.ArrayList;

import agersant.polaris.api.API;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.local.OfflineCache;
import agersant.polaris.api.remote.DownloadQueue;
import agersant.polaris.api.remote.ServerAPI;
import agersant.polaris.features.player.PlayerActivity;

/**
 * Created by agersant on 6/10/2017.
 */

public class PolarisService extends Service {

	private static final int MEDIA_NOTIFICATION = 1;
	private static final String MEDIA_INTENT_PAUSE = "MEDIA_INTENT_PAUSE";
	private static final String MEDIA_INTENT_PLAY = "MEDIA_INTENT_PLAY";
	private static final String MEDIA_INTENT_SKIP_NEXT = "MEDIA_INTENT_SKIP_NEXT";
	private static final String MEDIA_INTENT_SKIP_PREVIOUS = "MEDIA_INTENT_SKIP_PREVIOUS";
	private static final String MEDIA_INTENT_DISMISS = "MEDIA_INTENT_DISMISS";

	private final IBinder binder = new PolarisService.PolarisBinder();
	private DownloadQueue downloadQueue;
	private OfflineCache offlineCache;
	private PlaybackQueue playbackQueue;
	private Player player;
	private ServerAPI serverAPI;
	private LocalAPI localAPI;
	private API api;
	private BroadcastReceiver receiver;

	@Override
	public void onCreate() {
		super.onCreate();

		playbackQueue = new PlaybackQueue();
		player = new Player(this);
		offlineCache = new OfflineCache(this);
		downloadQueue = new DownloadQueue(this);
		serverAPI = new ServerAPI(this);
		localAPI = new LocalAPI(offlineCache);
		api = new API(this, serverAPI, localAPI);

		restoreStateFromDisk();

		IntentFilter filter = new IntentFilter();
		filter.addAction(AudioManager.ACTION_AUDIO_BECOMING_NOISY);
		filter.addAction(Player.PLAYBACK_ERROR);
		filter.addAction(Player.COMPLETED_TRACK);
		receiver = new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				switch (intent.getAction()) {
					case Player.COMPLETED_TRACK:
						skipNext();
						pushSystemNotification();
						break;
					case Player.PLAYBACK_ERROR:
						displayError();
						break;
					case AudioManager.ACTION_AUDIO_BECOMING_NOISY:
						pause();
						break;
				}
			}
		};
		registerReceiver(receiver, filter);
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		saveStateToDisk();
		unregisterReceiver(receiver);
	}

	@Override
	public IBinder onBind(Intent intent) {
		return binder;
	}

	public class PolarisBinder extends Binder {
		public PolarisService getService() {
			return PolarisService.this;
		}
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		handleIntent(intent);
		super.onStartCommand(intent, flags, startId);
		return START_NOT_STICKY;
	}


	// Internals
	private void advance(CollectionItem currentItem, int delta) {
		CollectionItem newTrack = playbackQueue.getNextTrack(currentItem, delta);
		if (newTrack != null) {
			play(newTrack);
		}
	}

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
			case MEDIA_INTENT_PAUSE:
				pause();
				break;
			case MEDIA_INTENT_PLAY:
				resume();
				break;
			case MEDIA_INTENT_SKIP_NEXT:
				skipNext();
				break;
			case MEDIA_INTENT_SKIP_PREVIOUS:
				skipPrevious();
				break;
			case MEDIA_INTENT_DISMISS:
				stopSelf();
				break;
		}
	}

	private void pushSystemNotification() {

		CollectionItem item = getCurrentItem();
		if (item == null) {
			return;
		}
		boolean isPlaying = isPlaying();

		TaskStackBuilder stackBuilder = TaskStackBuilder.create(this)
				.addParentStack(PlayerActivity.class)
				.addNextIntent(new Intent(this, PlayerActivity.class));
		PendingIntent tapPendingIntent = stackBuilder.getPendingIntent(0, PendingIntent.FLAG_UPDATE_CURRENT);

		Intent dismissIntent = new Intent(this, PolarisService.class);
		dismissIntent.setAction(MEDIA_INTENT_DISMISS);
		PendingIntent dismissPendingIntent = PendingIntent.getService(this, 0, dismissIntent, 0);

		Notification.Builder notificationBuilder = new Notification.Builder(this)
				.setShowWhen(false)
				.setSmallIcon(R.drawable.notification_icon)
				.setContentTitle(item.getTitle())
				.setContentText(item.getArtist())
				.setVisibility(Notification.VISIBILITY_PUBLIC)
				.setContentIntent(tapPendingIntent)
				.setDeleteIntent(dismissPendingIntent)
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

		if (isPlaying()) {
			startForeground(MEDIA_NOTIFICATION, notification);
		} else {
			stopForeground(false);
		}
	}

	private Notification.Action generateAction(int icon, int text, String intentAction) {
		Intent intent = new Intent(this, PolarisService.class);
		intent.setAction(intentAction);
		PendingIntent pendingIntent = PendingIntent.getService(this, 0, intent, 0);
		return new Notification.Action.Builder(Icon.createWithResource(this, icon), getResources().getString(text), pendingIntent).build();
	}

	private void saveStateToDisk() {
		File storage = new File(getCacheDir(), "playlist.v" + PlaybackQueueState.VERSION);

		// Gather state
		PlaybackQueueState state = new PlaybackQueueState();
		state.queueContent = playbackQueue.getContent();
		state.queueOrdering = getOrdering();
		CollectionItem currentItem = getCurrentItem();
		state.queueIndex = state.queueContent.indexOf(currentItem);
		state.trackProgress = getPosition();

		// Persist
		try (FileOutputStream out = new FileOutputStream(storage)) {
			try (ObjectOutputStream objOut = new ObjectOutputStream(out)) {
				objOut.writeObject(state);
			} catch (IOException e) {
				System.out.println("Error while saving PlaybackQueueState object: " + e);
			}
		} catch (IOException e) {
			System.out.println("Error while writing PlaybackQueueState file: " + e);
		}
	}

	private void restoreStateFromDisk() {
		File storage = new File(getCacheDir(), "playlist.v" + PlaybackQueueState.VERSION);
		try (FileInputStream in = new FileInputStream(storage)) {
			try (ObjectInputStream objIn = new ObjectInputStream(in)) {
				Object obj = objIn.readObject();
				if (obj instanceof PlaybackQueueState) {
					PlaybackQueueState state = (PlaybackQueueState) obj;
					playbackQueue.setContent(state.queueContent);
					setOrdering(state.queueOrdering);
					if (state.queueIndex >= 0) {
						CollectionItem currentItem = getItem(state.queueIndex);
						play(currentItem);
						pause();
						seekToAbsolute(state.trackProgress);
					}
				}
			} catch (ClassNotFoundException e) {
				System.out.println("Error while loading PlaybackQueueState object: " + e);
			}
		} catch (IOException e) {
			System.out.println("Error while reading PlaybackQueueState file: " + e);
		}
	}

	private boolean shouldAutoStart() {
		return isIdle() || (size() == 0 && !isPlaying());
	}


	// API
	public CollectionItem getCurrentItem() {
		return player.getCurrentItem();
	}

	public boolean isIdle() {
		return getCurrentItem() == null;
	}

	public void addItems(ArrayList<? extends CollectionItem> items) {
		if (items.isEmpty()) {
			return;
		}
		boolean autoStart = shouldAutoStart();
		playbackQueue.addItems(items);
		if (autoStart) {
			skipNext();
		}
	}

	public void addItem(CollectionItem item) {
		playbackQueue.addItem(item);
		boolean autoStart = shouldAutoStart();
		if (autoStart) {
			skipNext();
		}
	}

	public int size() {
		return playbackQueue.size();
	}

	public void remove(int position) {
		playbackQueue.remove(position);
	}

	public void clear() {
		playbackQueue.clear();
	}

	public CollectionItem getItem(int position) {
		return playbackQueue.getItem(position);
	}

	public PlaybackQueue.Ordering getOrdering() {
		return playbackQueue.getOrdering();
	}

	public void setOrdering(PlaybackQueue.Ordering ordering) {
		playbackQueue.setOrdering(ordering);
	}

	public void move(int fromPosition, int toPosition) {
		playbackQueue.move(fromPosition, toPosition);
	}

	public void swap(int fromPosition, int toPosition) {
		playbackQueue.swap(fromPosition, toPosition);
	}

	public boolean hasNextTrack() {
		return playbackQueue.hasNextTrack(player.getCurrentItem());
	}

	public boolean hasPreviousTrack() {
		return playbackQueue.hasPreviousTrack(player.getCurrentItem());
	}

	public void skipPrevious() {
		CollectionItem currentItem = player.getCurrentItem();
		advance(currentItem, -1);
	}

	public void skipNext() {
		CollectionItem currentItem = player.getCurrentItem();
		advance(currentItem, 1);
	}

	public void play(CollectionItem item) {
		player.play(item);
		pushSystemNotification();
	}

	public void pause() {
		player.pause();
		pushSystemNotification();
	}

	public void resume() {
		player.resume();
		pushSystemNotification();
	}

	public boolean isPlaying() {
		return player.isPlaying();
	}

	public long getDuration() {
		return player.getDuration();
	}

	public long getPosition() {
		return player.getPosition();
	}

	public void seekToRelative(float progress) {
		player.seekToRelative(progress);
	}

	public void seekToAbsolute(long position) {
		player.seekToAbsolute(position);
	}

	public boolean isUsing(MediaSource mediaSource) {
		return player.isUsing(mediaSource);
	}

	public boolean isOffline() {
		return api.isOffline();
	}

	public boolean hasLocalAudio(CollectionItem item) {
		return offlineCache.hasAudio(item.getPath());
	}

	public boolean isDownloading(CollectionItem item) {
		return downloadQueue.isDownloading(item);
	}

	public boolean isStreaming(CollectionItem item) {
		return downloadQueue.isStreaming(item);
	}

	public CollectionItem getNextItemToDownload() {
		return playbackQueue.getNextItemToDownload(getCurrentItem(), offlineCache, downloadQueue);
	}

	public int comparePriorities(CollectionItem a, CollectionItem b) {
		return playbackQueue.comparePriorities(getCurrentItem(), a, b);
	}

	public boolean makeSpace(CollectionItem forItem) {
		return offlineCache.makeSpace(forItem);
	}

	public void saveAudio(CollectionItem item, FileInputStream audio) {
		offlineCache.putAudio(item, audio);
	}

	public void saveImage(CollectionItem item, Bitmap image) {
		offlineCache.putImage(item, image);
	}

	public MediaSource downloadAudio(CollectionItem item) throws IOException {
		return downloadQueue.getAudio(item);
	}

	public API getAPI() {
		return api;
	}

	public ServerAPI getServerAPI() {
		return serverAPI;
	}

	public String getAuthCookieHeader() {
		return serverAPI.getCookieHeader();
	}

	public String getAuthRawHeader() {
		return serverAPI.getAuthorizationHeader();
	}
}
