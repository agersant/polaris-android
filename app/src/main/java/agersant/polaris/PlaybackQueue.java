package agersant.polaris;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.preference.PreferenceManager;

import java.util.ArrayList;
import java.util.Collections;

import agersant.polaris.api.local.OfflineCache;
import agersant.polaris.api.remote.DownloadQueue;

public class PlaybackQueue {

    public static final String CHANGED_ORDERING = "CHANGED_ORDERING";
    public static final String QUEUED_ITEM = "QUEUED_ITEM";
    public static final String QUEUED_ITEMS = "QUEUED_ITEMS";
    public static final String OVERWROTE_QUEUE = "OVERWROTE_QUEUE";
    public static final String NO_LONGER_EMPTY = "NO_LONGER_EMPTY";
    public static final String REMOVED_ITEM = "REMOVED_ITEM";
    public static final String REMOVED_ITEMS = "REMOVED_ITEMS";
    public static final String REORDERED_ITEMS = "REORDERED_ITEMS";

    private ArrayList<CollectionItem> content;
    private Ordering ordering;

    PlaybackQueue() {
        content = new ArrayList<>();
        ordering = Ordering.SEQUENCE;
    }

    ArrayList<CollectionItem> getContent() {
        return content;
    }

    void setContent(ArrayList<CollectionItem> content) {
        this.content = content;
        broadcast(PlaybackQueue.OVERWROTE_QUEUE);
    }

    // Return negative value if a is going to play before b, positive if a is going to play after b
    public int comparePriorities(CollectionItem currentItem, CollectionItem a, CollectionItem b) {
        final int currentIndex = content.indexOf(currentItem);
        int playlistSize = content.size();

        int scoreA = playlistSize + 1;
        int scoreB = playlistSize + 1;

        for (int i = 0; i < playlistSize; i++) {
            CollectionItem item = content.get(i);
            final String path = item.getPath();
            final int score = (playlistSize + i - currentIndex) % playlistSize;
            if (score < scoreA && path.equals(a.getPath())) {
                scoreA = score;
            }
            if (score < scoreB && path.equals(b.getPath())) {
                scoreB = score;
            }
        }

        return scoreA - scoreB;
    }

    private void addItemInternal(CollectionItem item) {
        CollectionItem newItem;
        try {
            newItem = item.clone();
        } catch (Exception e) {
            System.err.println("Error while cloning CollectionItem: " + e.toString());
            return;
        }
        content.add(newItem);
    }

    public void addItems(ArrayList<? extends CollectionItem> items) {
        boolean wasEmpty = size() == 0;
        for (CollectionItem item : items) {
            addItemInternal(item);
        }
        broadcast(PlaybackQueue.QUEUED_ITEMS);
        if (wasEmpty) {
            broadcast(PlaybackQueue.NO_LONGER_EMPTY);
        }
    }

    public void addItem(CollectionItem item) {
        boolean wasEmpty = size() == 0;
        addItemInternal(item);
        broadcast(PlaybackQueue.QUEUED_ITEM);
        if (wasEmpty) {
            broadcast(PlaybackQueue.NO_LONGER_EMPTY);
        }
    }

    public void remove(int position) {
        content.remove(position);
        broadcast(REMOVED_ITEM);
    }

    public void clear() {
        content.clear();
        broadcast(REMOVED_ITEMS);
    }

    public void swap(int fromPosition, int toPosition) {
        Collections.swap(content, fromPosition, toPosition);
        broadcast(REORDERED_ITEMS);
    }

    public void move(int fromPosition, int toPosition) {
        if (fromPosition == toPosition) {
            return;
        }
        int low = Math.min(fromPosition, toPosition);
        int high = Math.max(fromPosition, toPosition);
        int distance = fromPosition < toPosition ? -1 : 1;
        Collections.rotate(content.subList(low, high + 1), distance);
        broadcast(REORDERED_ITEMS);
    }

    public int size() {
        return content.size();
    }

    public CollectionItem getItem(int position) {
        return content.get(position);
    }

    CollectionItem getNextTrack(CollectionItem from, int delta) {
        if (content.isEmpty()) {
            return null;
        }

        if (ordering == Ordering.REPEAT_ONE) {
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

    public Ordering getOrdering() {
        return ordering;
    }

    public void setOrdering(Ordering ordering) {
        this.ordering = ordering;
        broadcast(CHANGED_ORDERING);
    }

    public boolean hasNextTrack(CollectionItem currentItem) {
        return getNextTrack(currentItem, 1) != null;
    }

    public boolean hasPreviousTrack(CollectionItem currentItem) {
        return getNextTrack(currentItem, -1) != null;
    }

    private void broadcast(String event) {
        PolarisApplication application = PolarisApplication.getInstance();
        Intent intent = new Intent();
        intent.setAction(event);
        application.sendBroadcast(intent);
    }

    public CollectionItem getNextItemToDownload(CollectionItem currentItem, OfflineCache offlineCache, DownloadQueue downloadQueue) {
        final int currentIndex = Math.max(0, content.indexOf(currentItem));

        int bestScore = 0;
        CollectionItem bestItem = null;

        int playlistSize = content.size();

        for (int i = 0; i < playlistSize; i++) {
            final int score = (playlistSize + i - currentIndex) % playlistSize;
            if (bestItem != null && score > bestScore) {
                continue;
            }
            CollectionItem item = content.get(i);
            if (item == currentItem) {
                continue;
            }
            if (offlineCache.hasAudio(item.getPath())) {
                continue;
            }
            if (downloadQueue.isDownloading(item)) {
                continue;
            }
            bestScore = score;
            bestItem = item;
        }

        PolarisApplication application = PolarisApplication.getInstance();
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(application);
        Resources resources = application.getResources();
        String numSongsToPreloadKey = resources.getString(R.string.pref_key_num_songs_preload);
        String numSongsToPreloadString = preferences.getString(numSongsToPreloadKey, "0");
        int numSongsToPreload = Integer.parseInt(numSongsToPreloadString);
        if (numSongsToPreload >= 0 && bestScore > numSongsToPreload) {
            bestItem = null;
        }

        return bestItem;
    }

    public enum Ordering {
        SEQUENCE,
        REPEAT_ONE,
        REPEAT_ALL,
    }
}
