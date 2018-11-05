package agersant.polaris;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;

import java.util.Timer;
import java.util.TimerTask;

import agersant.polaris.api.remote.DownloadQueue;


public class PolarisDownloadService extends Service {

	private final IBinder binder = new PolarisDownloadService.PolarisBinder();

	private DownloadQueue downloadQueue;
	private Timer timer;

	@Override
	public void onCreate() {
		super.onCreate();

		PolarisState state = PolarisApplication.getState();
		downloadQueue = state.downloadQueue;

		timer = new Timer();
		timer.scheduleAtFixedRate(new TimerTask() {
			@Override
			public void run() {
				downloadQueue.downloadNext();
			}
		}, 1500, 500);
	}

	@Override
	public void onDestroy() {
		timer.cancel();
	}

	@Override
	public IBinder onBind(Intent intent) {
		return binder;
	}

	private class PolarisBinder extends Binder {
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		super.onStartCommand(intent, flags, startId);
		return START_NOT_STICKY;
	}

}
