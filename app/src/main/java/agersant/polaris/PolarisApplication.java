package agersant.polaris;

import android.app.Application;
import android.content.Intent;

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

		Intent intent = new Intent(this, PolarisService.class);
		startService(intent);
	}

}
