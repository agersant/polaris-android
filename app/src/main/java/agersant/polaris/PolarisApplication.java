package agersant.polaris;

import android.app.Application;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;

import agersant.polaris.api.API;
import agersant.polaris.api.local.LocalAPI;
import agersant.polaris.api.local.OfflineCache;
import agersant.polaris.api.remote.DownloadQueue;
import agersant.polaris.api.remote.ServerAPI;

public class PolarisApplication extends Application {

	private static PolarisApplication instance;

	private MediaPlayerService mediaPlayerService;

	public static PolarisApplication getInstance() {
		assert instance != null;
		return instance;
	}

	@Override
	public void onCreate() {
		super.onCreate();
		OfflineCache.init(this);
		ServerAPI.init(this);
		LocalAPI.init();
		API.init(this);

		DownloadQueue.init(this);
		initMediaPlayerService();
		instance = this;
	}

	private void initMediaPlayerService() {

		ServiceConnection serviceConnection = new ServiceConnection() {
			@Override
			public void onServiceConnected(ComponentName name, IBinder service) {
				MediaPlayerService.MediaPlayerBinder binder = (MediaPlayerService.MediaPlayerBinder) service;
				mediaPlayerService = binder.getService();
			}

			@Override
			public void onServiceDisconnected(ComponentName componentName) {
			}
		};

		Intent intent = new Intent(this, MediaPlayerService.class);
		bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
		startService(intent);
	}

	public MediaPlayerService getMediaPlayerService() {
		return mediaPlayerService;
	}

}
