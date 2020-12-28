package agersant.polaris;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.graphics.drawable.Icon;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
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
import androidx.navigation.NavDeepLinkBuilder;


public class PolarisPlaybackService extends Service {

    private static final int MEDIA_NOTIFICATION = 100;
    private static final String MEDIA_INTENT_PAUSE = "MEDIA_INTENT_PAUSE";
    private static final String MEDIA_INTENT_PLAY = "MEDIA_INTENT_PLAY";
    private static final String MEDIA_INTENT_SKIP_NEXT = "MEDIA_INTENT_SKIP_NEXT";
    private static final String MEDIA_INTENT_SKIP_PREVIOUS = "MEDIA_INTENT_SKIP_PREVIOUS";
    private static final String MEDIA_INTENT_DISMISS = "MEDIA_INTENT_DISMISS";
    public static final String APP_INTENT_COLD_BOOT = "POLARIS_PLAYBACK_SERVICE_COLD_BOOT";

    private static final String NOTIFICATION_CHANNEL_ID = "POLARIS_NOTIFICATION_CHANNEL_ID";

    private static final long MEDIA_SESSION_UPDATE_DELAY = 5000;
    private static final long AUTO_SAVE_DELAY = 5000;

    private final IBinder binder = new PolarisPlaybackService.PolarisBinder();
    private BroadcastReceiver receiver;
    private AudioFocusRequest audioFocusRequest;
    private AudioManager audioManager;
    private Notification notification;
    private CollectionItem notificationItem;
    private NotificationManager notificationManager;
    private Handler autoSaveHandler;
    private Runnable autoSaveRunnable;

    private Runnable mediaSessionUpdateRunnable;
    private Handler mediaSessionUpdateHandler;

    private API api;
    private PolarisPlayer player;
    private PlaybackQueue playbackQueue;

    private MediaSessionCompat mediaSession;

    private class MediaSessionCallback extends MediaSessionCompat.Callback {
        private final PolarisPlayer player;

        MediaSessionCallback(PolarisPlayer player) {
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

        audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        if (Build.VERSION.SDK_INT >= 26) {
            AudioAttributes playbackAttributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build();
            audioFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(playbackAttributes)
                .build();
        }

        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (Build.VERSION.SDK_INT > 25) {
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
                        stopMediaSessionUpdates();
                        updateMediaSessionState(PlaybackStateCompat.STATE_ERROR);
                        displayError();
                        break;
                    case PolarisPlayer.PLAYING_TRACK:
                    case PolarisPlayer.RESUMED_TRACK:
                        requestAudioFocus();
                        startMediaSessionUpdates();
                        updateMediaSessionState(PlaybackStateCompat.STATE_PLAYING);
                        pushSystemNotification();
                        break;
                    case PolarisPlayer.PAUSED_TRACK:
                        abandonAudioFocus();
                        stopMediaSessionUpdates();
                        updateMediaSessionState(PlaybackStateCompat.STATE_PAUSED);
                        pushSystemNotification();
                        saveStateToDisk();
                        break;
                    case PolarisPlayer.COMPLETED_TRACK:
                        abandonAudioFocus();
                        stopMediaSessionUpdates();
                        updateMediaSessionState(PlaybackStateCompat.STATE_STOPPED);
                        break;
                    case AudioManager.ACTION_AUDIO_BECOMING_NOISY:
                        player.pause();
                        break;
                }
            }
        };
        registerReceiver(receiver, filter);

        autoSaveRunnable = () -> {
            saveStateToDisk();
            autoSaveHandler.postDelayed(autoSaveRunnable, AUTO_SAVE_DELAY);
        };
        autoSaveHandler = new Handler();
        autoSaveHandler.postDelayed(autoSaveRunnable, AUTO_SAVE_DELAY);

        pushSystemNotification();

        mediaSession = new MediaSessionCompat(this, getPackageName());
        mediaSession.setCallback(new MediaSessionCallback(player));
        mediaSession.setActive(true);

        updateMediaSessionState(PlaybackStateCompat.STATE_NONE);

        mediaSessionUpdateRunnable = () -> {
            updateMediaSessionState(player.isPlaying() ? PlaybackStateCompat.STATE_PLAYING : PlaybackStateCompat.STATE_PAUSED);
            mediaSessionUpdateHandler.postDelayed(mediaSessionUpdateRunnable, MEDIA_SESSION_UPDATE_DELAY);
        };
        mediaSessionUpdateHandler = new Handler();
        startMediaSessionUpdates();
    }

    private void updateMediaSessionState(int state) {
        PlaybackStateCompat.Builder builder = new PlaybackStateCompat.Builder();
        builder.setActions(PlaybackStateCompat.ACTION_PLAY | PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_PAUSE | PlaybackStateCompat.ACTION_SKIP_TO_NEXT | PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS);
        builder.setState(state, (long) player.getCurrentPosition(), 1);
        mediaSession.setPlaybackState(builder.build());

        MediaMetadataCompat.Builder metadataBuilder = new MediaMetadataCompat.Builder();
        CollectionItem currentItem = player.getCurrentItem();
        if (currentItem != null) {
            metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_TITLE, currentItem.getTitle());
            metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_ARTIST, currentItem.getArtist());
            metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_ALBUM, currentItem.getAlbum());
            metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_ALBUM_ARTIST, currentItem.getAlbumArtist());
            metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_TRACK_NUMBER, currentItem.getTrackNumber());
            metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_DISC_NUMBER, currentItem.getDiscNumber());
        }
        metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_DURATION, (long) player.getDuration());
        mediaSession.setMetadata(metadataBuilder.build());
    }

    @Override
    public void onDestroy() {
        mediaSession.release();
        unregisterReceiver(receiver);
        autoSaveHandler.removeCallbacksAndMessages(null);
        stopMediaSessionUpdates();
        super.onDestroy();
    }

    private void startMediaSessionUpdates() {
        stopMediaSessionUpdates();
        mediaSessionUpdateHandler.postDelayed(mediaSessionUpdateRunnable, MEDIA_SESSION_UPDATE_DELAY);
    }

    private void stopMediaSessionUpdates() {
        mediaSessionUpdateHandler.removeCallbacksAndMessages(null);
    }

    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    private class PolarisBinder extends Binder {
    }

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

    private void requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= 26) {
            audioManager.requestAudioFocus(audioFocusRequest);
        }
    }

    private void abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= 26) {
            audioManager.abandonAudioFocusRequest(audioFocusRequest);
        }
    }

    private void pushSystemNotification() {

        boolean isPlaying = player.isPlaying();
        final CollectionItem item = player.getCurrentItem();
        if (item == null) {
            return;
        }

        // On tap action
        PendingIntent tapPendingIntent = new NavDeepLinkBuilder(this)
            .setGraph(R.navigation.nav_graph)
            .setDestination(R.id.nav_now_playing)
            .createPendingIntent();

        // On dismiss action
        Intent dismissIntent = new Intent(this, PolarisPlaybackService.class);
        dismissIntent.setAction(MEDIA_INTENT_DISMISS);
        PendingIntent dismissPendingIntent = PendingIntent.getService(this, 0, dismissIntent, 0);

        // Create notification
        final Notification.Builder notificationBuilder;
        if (Build.VERSION.SDK_INT > 25) {
            notificationBuilder = new Notification.Builder(this, NOTIFICATION_CHANNEL_ID);
        } else {
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
        for (CollectionItem item : playbackQueue.getContent()) {
            try {
                state.queueContent.add(item.clone());
            } catch (CloneNotSupportedException e) {
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
