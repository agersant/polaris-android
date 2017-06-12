package agersant.polaris.api.remote;

import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultDataSource;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;

import agersant.polaris.PolarisService;

/**
 * Created by agersant on 6/11/2017.
 */

public final class PolarisExoPlayerDataSourceFactory implements DataSource.Factory {

	private class PolarisExoPlayerHttpDataSourceFactory implements DataSource.Factory {

		private PolarisService service;

		PolarisExoPlayerHttpDataSourceFactory(PolarisService service) {
			this.service = service;
		}

		@Override
		public DataSource createDataSource() {
			DefaultHttpDataSource defaultHttpDataSource = new DefaultHttpDataSource("Polaris Android", null);
			String authCookie = service.getAuthCookieHeader();
			if (authCookie != null) {
				defaultHttpDataSource.setRequestProperty("Cookie", authCookie);
			} else {
				String authRaw = service.getAuthRawHeader();
				defaultHttpDataSource.setRequestProperty("Authorization", authRaw);
			}
			return defaultHttpDataSource;
		}
	}

	PolarisService service;
	PolarisExoPlayerHttpDataSourceFactory httpDataSourceFactory;

	public PolarisExoPlayerDataSourceFactory(PolarisService service) {
		this.service = service;
		httpDataSourceFactory = new PolarisExoPlayerHttpDataSourceFactory(service);
	}

	@Override
	public DefaultDataSource createDataSource() {
		return new DefaultDataSource(service, null, httpDataSourceFactory.createDataSource());
	}
}
