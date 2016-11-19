package agersant.polaris;

import java.util.ArrayList;
import java.util.Collections;

public class PlaybackQueue {

    private static PlaybackQueue instance;

    private ArrayList<CollectionItem> content;

    private PlaybackQueue() {
        content = new ArrayList<>();
    }

    public static PlaybackQueue getInstance() {
        if (instance == null) {
            instance = new PlaybackQueue();
        }
        return instance;
    }

    public void add(CollectionItem item) {
        try {
            content.add(item.clone());
        } catch (Exception e) {
            System.err.println("Error while queuing item: " + e.toString());
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
