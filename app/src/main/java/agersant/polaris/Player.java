package agersant.polaris;

import android.content.Context;
import android.content.Intent;

import agersant.polaris.api.ServerAPI;

public class Player {

    public static final String PLAYING_TRACK = "PLAYING_TRACK";
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
        PolarisApplication application = PolarisApplication.getInstance();

        currentItem = item;
        String url = serverAPI.getMediaURL(item.getPath());
        application.getMediaPlayerService().play(url);

        Intent intent = new Intent();
        intent.setAction(Player.PLAYING_TRACK);
        application.sendBroadcast(intent);
    }

    public boolean isIdle() {
        return currentItem == null;
    }

    public CollectionItem getCurrentItem() {
        return currentItem;
    }
}
