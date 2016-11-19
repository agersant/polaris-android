package agersant.polaris;

import java.util.ArrayList;

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

    public int size() {
        return content.size();
    }

    public CollectionItem getItem(int position) {
        return content.get(position);
    }

}
