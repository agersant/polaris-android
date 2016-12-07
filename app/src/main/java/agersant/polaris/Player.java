package agersant.polaris;

import android.content.Context;

import agersant.polaris.api.ServerAPI;

public class Player {

    public static final String PLAYING_TRACK = "PLAYING_TRACK";
    public static final String PAUSED_TRACK = "PAUSED_TRACK";
    public static final String RESUMED_TRACK = "RESUMED_TRACK";
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
        String url = serverAPI.getMediaURL(item.getPath());
        application.getMediaPlayerService().play(url);
        currentItem = item;
    }

    public void pause() {
        PolarisApplication application = PolarisApplication.getInstance();
        application.getMediaPlayerService().pause();
    }

    public void resume() {
        PolarisApplication application = PolarisApplication.getInstance();
        application.getMediaPlayerService().resume();
    }

    public boolean isPlaying() {
        PolarisApplication application = PolarisApplication.getInstance();
        return application.getMediaPlayerService().isPlaying();
    }

    public boolean isIdle() {
        return currentItem == null;
    }

    public CollectionItem getCurrentItem() {
        return currentItem;
    }
}
