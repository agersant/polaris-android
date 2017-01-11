package agersant.polaris;

import android.content.Intent;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Random;

public class PlaybackQueue {

	public static final String CHANGED_ORDERING = "CHANGED_ORDERING";
	public static final String QUEUED_ITEM = "QUEUED_ITEM";
	public static final String QUEUED_ITEMS = "QUEUED_ITEMS";
	public static final String REMOVED_ITEM = "REMOVED_ITEM";
	public static final String REMOVED_ITEMS = "REMOVED_ITEMS";
	public static final String REORDERED_ITEMS = "REORDERED_ITEMS";

	private static PlaybackQueue instance;
	private Random rng;
	private ArrayList<CollectionItem> content;
	private Player player;
	private Ordering ordering;

	private PlaybackQueue() {
		rng = new Random();
		player = Player.getInstance();
		content = new ArrayList<>();
		ordering = Ordering.SEQUENCE;
	}

	public static PlaybackQueue getInstance() {
		if (instance == null) {
			instance = new PlaybackQueue();
		}
		return instance;
	}

	public void addItems(ArrayList<CollectionItem> items) {
		for (CollectionItem item : items) {
			addItemInternal(item);
		}
		broadcast(QUEUED_ITEMS);
	}

	public void addItem(CollectionItem item) {
		addItemInternal(item);
		broadcast(QUEUED_ITEM);
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
		if (player.isIdle()) {
			player.play(newItem);
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

	public Ordering getOrdering() {
		return ordering;
	}

	public void setOrdering(Ordering ordering) {
		this.ordering = ordering;
		broadcast(CHANGED_ORDERING);
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

	public boolean hasNextTrack() {
		CollectionItem currentItem = player.getCurrentItem();
		return getNextTrack(currentItem, 1) != null;
	}

	public boolean hasPreviousTrack() {
		CollectionItem currentItem = player.getCurrentItem();
		return getNextTrack(currentItem, -1) != null;
	}

	private void broadcast(String event) {
		PolarisApplication application = PolarisApplication.getInstance();
		Intent intent = new Intent();
		intent.setAction(event);
		application.sendBroadcast(intent);
	}

	public enum Ordering {
		SEQUENCE,
		RANDOM,
		REPEAT_ONE,
		REPEAT_ALL,
	}
}
