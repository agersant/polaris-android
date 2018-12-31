package agersant.polaris;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Binder;
import android.os.Handler;
import android.os.IBinder;

import agersant.polaris.api.API;
import agersant.polaris.api.remote.ServerAPI;


public class PolarisScrobbleService extends Service {

	private final IBinder binder = new PolarisScrobbleService.PolarisBinder();
	private BroadcastReceiver receiver;
	private Handler tickHandler;
	private Runnable tickRunnable;

	private API api;
	private ServerAPI serverAPI;
	private PolarisPlayer player;

	static private final int TICK_DELAY = 5000; // ms

	private boolean seekedWithinTrack;
	private boolean scrobbledTrack;

	@Override
	public void onCreate() {
		super.onCreate();

		PolarisState state = PolarisApplication.getState();
		api = state.api;
		player = state.player;
		serverAPI = state.serverAPI;

		IntentFilter filter = new IntentFilter();
		filter.addAction(PolarisPlayer.PLAYING_TRACK);
		filter.addAction(PolarisPlayer.COMPLETED_TRACK);
		filter.addAction(PolarisPlayer.RESUMED_TRACK);
		filter.addAction(PolarisPlayer.SEEKING_WITHIN_TRACK);
		receiver = new BroadcastReceiver() {
			@Override
			public void onReceive(Context context, Intent intent) {
				switch (intent.getAction()) {
					case PolarisPlayer.COMPLETED_TRACK:
						seekedWithinTrack = false;
						scrobbledTrack = false;
						break;
					case PolarisPlayer.PLAYING_TRACK:
						seekedWithinTrack = false;
						scrobbledTrack = false;
						nowPlaying();
						break;
					case PolarisPlayer.RESUMED_TRACK:
						nowPlaying();
						break;
					case PolarisPlayer.SEEKING_WITHIN_TRACK:
						seekedWithinTrack = true;
						break;
				}
			}
		};
		registerReceiver(receiver, filter);

		seekedWithinTrack = false;
		scrobbledTrack = false;

		tickRunnable = () -> {
			tick();
			tickHandler.postDelayed(tickRunnable, TICK_DELAY);
		};
		tickHandler = new Handler();
		tickHandler.postDelayed(tickRunnable, TICK_DELAY);

		nowPlaying();
	}

	@Override
	public void onDestroy() {
		unregisterReceiver(receiver);
		tickHandler.removeCallbacksAndMessages(null);
		super.onDestroy();
	}

	@Override
	public IBinder onBind(Intent intent) {
		return binder;
	}

	private class PolarisBinder extends Binder {	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		super.onStartCommand(intent, flags, startId);
		return START_NOT_STICKY;
	}

	private void nowPlaying() {
		if (api.isOffline()) {
			return;
		}
		CollectionItem currentItem = player.getCurrentItem();
		if (currentItem == null) {
			return;
		}
		serverAPI.setLastFMNowPlaying(currentItem.getPath());
	}

	private void tick() {
		if (api.isOffline()) {
			return;
		}
		if (scrobbledTrack || seekedWithinTrack) {
			return;
		}
		if (player.getCurrentItem() == null) {
			return;
		}
		if (!player.isPlaying()) {
			return;
		}
		float duration = player.getDuration() / 1000; // in seconds
		float currentTime = player.getCurrentPosition() / 1000; // in seconds
		if (currentTime <= 0.f || duration <= 0.f) {
			return;
		}
		final boolean shouldScrobble = duration > 30 && (currentTime > duration/2 || currentTime > 4*60);
		if (!shouldScrobble) {
			return;
		}
		serverAPI.scrobbleOnLastFM(player.getCurrentItem().getPath());
		scrobbledTrack = true;
	}
}
