package agersant.polaris;

import android.content.Context;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.util.ArrayList;

/**
 * Created by agersant on 4/29/2017.
 */

public class PlaybackQueueState implements Serializable {

	private static int VERSION = 2;

	private static File storage;

	ArrayList<CollectionItem> queueContent;
	int queueIndex;
	PlaybackQueue.Ordering queueOrdering;
	float trackProgress;

	PlaybackQueueState() {
		queueContent = new ArrayList<>();
		queueOrdering = PlaybackQueue.Ordering.SEQUENCE;
		queueIndex = -1;
		trackProgress = 0;
	}

	static void init(Context context) {
		storage = new File(context.getCacheDir(), "playlist.v" + VERSION);
	}

	public static void saveToDisk() {
		PlaybackQueueState state = PlaybackQueue.getInstance().getState();
		try (FileOutputStream out = new FileOutputStream(storage)) {
			try (ObjectOutputStream objOut = new ObjectOutputStream(out)) {
				objOut.writeObject(state);
			} catch (IOException e) {
				System.out.println("Error while saving PlaybackQueueState object: " + e);
			}
		} catch (IOException e) {
			System.out.println("Error while writing PlaybackQueueState file: " + e);
		}
	}

	static void loadFromDisk() {
		try (FileInputStream in = new FileInputStream(storage)) {
			try (ObjectInputStream objIn = new ObjectInputStream(in)) {
				Object obj = objIn.readObject();
				if (obj instanceof PlaybackQueueState) {
					PlaybackQueueState state = (PlaybackQueueState) obj;
					PlaybackQueue.getInstance().restore(state);
				}
			} catch (ClassNotFoundException e) {
				System.out.println("Error while loading PlaybackQueueState object: " + e);
			}
		} catch (IOException e) {
			System.out.println("Error while reading PlaybackQueueState file: " + e);
		}
	}

}
