package agersant.polaris.api.remote;

import java.io.IOException;

import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

class RequestQueue {

	private final OkHttpClient client;

	RequestQueue(Auth auth) {
		this.client = new OkHttpClient.Builder()
				.retryOnConnectionFailure(true)
				.addInterceptor(auth)
				.build();
	}

	ResponseBody requestSync(Request request) throws IOException {
		Response response = client.newCall(request).execute();
		if (!response.isSuccessful()) {
			throw new IOException("Request failed with error code: " + response.code());
		}
		return response.body();
	}

	void requestAsync(Request request, final Callback callback) {
		client.newCall(request).enqueue(callback);
	}

}

