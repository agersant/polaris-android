package agersant.polaris;

import android.app.Application;

import agersant.polaris.api.remote.RequestQueue;

public class PolarisApplication extends Application {

	private static PolarisApplication instance;

	public static PolarisApplication getInstance() {
		assert instance != null;
		return instance;
	}

	@Override
	public void onCreate() {
		super.onCreate();
		instance = this;
		RequestQueue.init(this);
	}

}
