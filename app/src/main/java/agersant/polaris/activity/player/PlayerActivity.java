package agersant.polaris.activity.player;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.Player;
import agersant.polaris.R;
import agersant.polaris.activity.PolarisActivity;
import agersant.polaris.api.ServerAPI;
import agersant.polaris.ui.NetworkImage;

public class PlayerActivity extends PolarisActivity {

    private BroadcastReceiver receiver;
    private PlaybackQueue queue;
    private Player player;
    private ImageView artwork;
    private ImageView pauseToggle;
    private ImageView skipNext;
    private ImageView skipPrevious;

    public PlayerActivity() {
        super(R.string.now_playing, R.id.nav_now_playing);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_player);
        super.onCreate(savedInstanceState);
        queue = PlaybackQueue.getInstance(this);
        player = Player.getInstance(this);
        artwork = (ImageView) findViewById(R.id.artwork);
        pauseToggle = (ImageView) findViewById(R.id.pause_toggle);
        skipNext = (ImageView) findViewById(R.id.skip_next);
        skipPrevious = (ImageView) findViewById(R.id.skip_previous);
    }

    @Override
    public void onResume() {
        super.onResume();
        updateContent();
        updateControls();
    }

    private void subscribeToEvents() {
        final PlayerActivity that = this;
        IntentFilter filter = new IntentFilter();
        filter.addAction(Player.PLAYING_TRACK);
        filter.addAction(Player.PAUSED_TRACK);
        filter.addAction(Player.RESUMED_TRACK);
        filter.addAction(PlaybackQueue.CHANGED_ORDERING);
        filter.addAction(PlaybackQueue.QUEUED_ITEM);
        filter.addAction(PlaybackQueue.QUEUED_ITEMS);
        filter.addAction(PlaybackQueue.REMOVED_ITEM);
        filter.addAction(PlaybackQueue.REMOVED_ITEMS);
        filter.addAction(PlaybackQueue.REORDERED_ITEMS);
        receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                switch (intent.getAction()) {
                    case Player.PLAYING_TRACK:
                        that.updateContent();
                        that.updateControls();
                        break;
                    case Player.PAUSED_TRACK:
                    case Player.RESUMED_TRACK:
                    case PlaybackQueue.CHANGED_ORDERING:
                    case PlaybackQueue.REMOVED_ITEM:
                    case PlaybackQueue.REMOVED_ITEMS:
                    case PlaybackQueue.REORDERED_ITEMS:
                    case PlaybackQueue.QUEUED_ITEM:
                    case PlaybackQueue.QUEUED_ITEMS:
                        that.updateControls();
                        break;
                }
            }
        };
        registerReceiver(receiver, filter);
    }

    @Override
    public void onStart() {
        subscribeToEvents();
        super.onResume();
    }

    @Override
    public void onStop() {
        unregisterReceiver(receiver);
        receiver = null;
        super.onPause();
    }

    public void skipPrevious(View view) {
        queue.skipPrevious();
    }

    public void skipNext(View view) {
        queue.skipNext();
    }

    private void updateContent() {
        CollectionItem currentItem = player.getCurrentItem();
        if (currentItem != null) {
            populateWithTrack(currentItem);
        }
    }

    private void updateControls() {
        final float disabledAlpha = 0.2f;

        int playPauseIcon = player.isPlaying() ? R.drawable.ic_pause_black_24dp : R.drawable.ic_play_arrow_black_24dp;
        pauseToggle.setImageResource(playPauseIcon);
        pauseToggle.setAlpha(player.isIdle() ? disabledAlpha : 1.f);


        if (queue.hasNextTrack()) {
            skipNext.setClickable(true);
            skipNext.setAlpha(1.0f);
        } else {
            skipNext.setClickable(false);
            skipNext.setAlpha(disabledAlpha);
        }

        if (queue.hasPreviousTrack()) {
            skipPrevious.setClickable(true);
            skipPrevious.setAlpha(1.0f);
        } else {
            skipPrevious.setClickable(false);
            skipPrevious.setAlpha(disabledAlpha);
        }
    }

    private void populateWithBlank() {
        // TODO?
    }

    private void populateWithTrack(CollectionItem item) {
        assert item != null;

        String title = item.getTitle();
        if (title != null) {
            toolbar.setTitle(title);
        }

        String artist = item.getArtist();
        if (artist != null) {
            toolbar.setSubtitle(artist);
        }

        String artworkPath = item.getArtwork();
        if (artworkPath != null) {
            ServerAPI serverAPI = ServerAPI.getInstance(this);
            String url = serverAPI.getMediaURL(artworkPath);
            NetworkImage.load(url, artwork);
        }
    }

    public void togglePause(View view) {
        if (player.isPlaying()) {
            player.pause();
        } else {
            player.resume();
        }
    }

}
