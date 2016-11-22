package agersant.polaris;

import android.content.Context;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Random;

public class PlaybackQueue {

    public enum Ordering {
        SEQUENCE,
        RANDOM,
        REPEAT_ONE,
        REPEAT_ALL,
    }

    private static PlaybackQueue instance;

    private Random rng;
    private ArrayList<CollectionItem> content;
    private Player player;
    private Ordering ordering;

    private PlaybackQueue(Context context) {
        rng = new Random();
        player = Player.getInstance(context);
        content = new ArrayList<>();
        ordering = Ordering.SEQUENCE;
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

    public void clear() {
        content.clear();
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

    private CollectionItem getNextTrack(CollectionItem from, int delta) {
        if (content.isEmpty()) {
            return null;
        }

        if (ordering == Ordering.RANDOM) {
            int newIndex = rng.nextInt(content.size());
            return content.get(newIndex);
        } else if (ordering == Ordering.REPEAT_ONE) {
            return from;
        } else {
            int currentIndex = content.indexOf(from);
            if (currentIndex < 0) {
                return content.get(0);
            } else {
                int newIndex = currentIndex + delta;
                if (newIndex >= 0 && newIndex < content.size()) {
                    return content.get(newIndex);
                } else if (ordering == Ordering.REPEAT_ALL) {
                    if (delta > 0) {
                        return content.get(0);
                    } else {
                        return content.get(content.size() - 1);
                    }
                } else {
                    return null;
                }
            }
        }
    }

    public void setOrdering(Ordering ordering) {
        this.ordering = ordering;
    }

    private void advance(int delta) {
        CollectionItem currentItem = player.getCurrentItem();
        CollectionItem newTrack = getNextTrack(currentItem, delta);
        if (newTrack != null) {
            player.play(newTrack);
        }
    }

    public void skipPrevious() {
        advance(-1);
    }

    public void skipNext() {
        advance(1);
    }
}
