package agersant.polaris.activity.player;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
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
        subscribeToEvents();
    }

    @Override
    public void onResume() {
        super.onResume();
        updateContent();
    }

    private void subscribeToEvents() {
        final PlayerActivity that = this;
        IntentFilter filter = new IntentFilter();
        filter.addAction(Player.PLAYING_TRACK);
        receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                switch (intent.getAction()) {
                    case Player.PLAYING_TRACK:
                        that.updateContent();
                        break;
                }
            }
        };
        registerReceiver(receiver, filter);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(receiver);
    }

    private void updateContent() {
        CollectionItem currentItem = player.getCurrentItem();
        if (currentItem == null) {
            populateWithBlank();
        } else {
            populateWithTrack(currentItem);
        }
    }

    private void populateWithBlank() {

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

}
