package agersant.polaris;

import java.io.Serializable;
import java.util.ArrayList;


class PlaybackQueueState implements Serializable {

    static final int VERSION = 4;

    ArrayList<CollectionItem> queueContent;
    int queueIndex;
    PlaybackQueue.Ordering queueOrdering;
    float trackProgress;

    PlaybackQueueState() {
        queueContent = new ArrayList<>();
        queueOrdering = PlaybackQueue.Ordering.SEQUENCE;
        queueIndex = -1;
        trackProgress = 0.f;
    }

}
