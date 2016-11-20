package agersant.polaris;

import android.content.Context;

import agersant.polaris.api.ServerAPI;

public class Player {

    private static Player instance;

    private CollectionItem currentItem;
    private ServerAPI serverAPI;

    private Player(Context context) {
        serverAPI = ServerAPI.getInstance(context);
    }

    public static Player getInstance(Context context) {
        if (instance == null) {
            instance = new Player(context);
        }
        return instance;
    }

    public void play(CollectionItem item) {
        currentItem = item;
        String url = serverAPI.getURL() + "/serve/" + item.getPath();
        PolarisApplication.getInstance().getMediaPlayerService().play(url);
    }

    public boolean isIdle() {
        return currentItem == null;
    }

    public CollectionItem getCurrentItem() {
        return currentItem;
    }
}
