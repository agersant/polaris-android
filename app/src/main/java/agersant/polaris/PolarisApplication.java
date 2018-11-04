package agersant.polaris;

import android.app.Application;
import android.content.Intent;

public class PolarisApplication extends Application {

	private static PolarisApplication instance;

	private static PolarisState state;

	public static PolarisApplication getInstance() {
		assert instance != null;
		return instance;
	}

	public static PolarisState getState() {
		assert state != null;
		return state;
	}

	@Override
	public void onCreate() {
		super.onCreate();
		instance = this;
		state = new PolarisState(this);


		Intent intent = new Intent(this, PolarisService.class);
		startService(intent);
	}

}
