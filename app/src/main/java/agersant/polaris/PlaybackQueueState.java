package agersant.polaris;

import java.io.Serializable;
import java.util.ArrayList;


class PlaybackQueueState implements Serializable {

	static final int VERSION = 3;

	ArrayList<CollectionItem> queueContent;
	int queueIndex;
	PlaybackQueue.Ordering queueOrdering;
	long trackProgress;

	PlaybackQueueState() {
		queueContent = new ArrayList<>();
		queueOrdering = PlaybackQueue.Ordering.SEQUENCE;
		queueIndex = -1;
		trackProgress = 0;
	}

}
