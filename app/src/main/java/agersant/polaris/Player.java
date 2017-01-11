package agersant.polaris;

public class Player {

	public static final String PLAYING_TRACK = "PLAYING_TRACK";
	public static final String PAUSED_TRACK = "PAUSED_TRACK";
	public static final String RESUMED_TRACK = "RESUMED_TRACK";
	public static final String COMPLETED_TRACK = "COMPLETED_TRACK";
	private static Player instance;

	private CollectionItem currentItem;

	private Player() {
	}

	public static Player getInstance() {
		if (instance == null) {
			instance = new Player();
		}
		return instance;
	}

	public void play(CollectionItem item) {
		PolarisApplication application = PolarisApplication.getInstance();
		application.getMediaPlayerService().play(item);
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

	public void seekTo(float progress) {
		PolarisApplication application = PolarisApplication.getInstance();
		application.getMediaPlayerService().seekTo(progress);
	}

	public float getProgress() {
		PolarisApplication application = PolarisApplication.getInstance();
		return application.getMediaPlayerService().getProgress();
	}

	public CollectionItem getCurrentItem() {
		return currentItem;
	}
}
