package agersant.polaris.activity.player;

import android.os.Bundle;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.Player;
import agersant.polaris.R;
import agersant.polaris.activity.PolarisActivity;

public class PlayerActivity extends PolarisActivity {

    PlaybackQueue queue;
    Player player;

    public PlayerActivity() {
        super(R.string.now_playing, R.id.nav_now_playing);
        queue = PlaybackQueue.getInstance(this);
        player = Player.getInstance(this);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_player);
        super.onCreate(savedInstanceState);
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
    }

}
