package agersant.polaris;

import android.content.Context;

import java.util.ArrayList;
import java.util.Collections;

public class PlaybackQueue {

    private static PlaybackQueue instance;

    private ArrayList<CollectionItem> content;
    private Player player;

    private PlaybackQueue(Context context) {
        player = Player.getInstance(context);
        content = new ArrayList<>();
    }

    public static PlaybackQueue getInstance(Context context) {
        if (instance == null) {
            instance = new PlaybackQueue(context);
        }
        return instance;
    }

    public void add(CollectionItem item) {
        CollectionItem newItem;
        try {
            newItem = item.clone();
        } catch (Exception e) {
            System.err.println("Error while cloning CollectionItem: " + e.toString());
            return;
        }

        content.add(newItem);
        if (player.isIdle()) {
            player.play(newItem);
        }
    }

    public void remove(int position) {
        content.remove(position);
    }

    public void swap(int fromPosition, int toPosition) {
        Collections.swap(content, fromPosition, toPosition);
    }

    public int size() {
        return content.size();
    }

    public CollectionItem getItem(int position) {
        return content.get(position);
    }
}
