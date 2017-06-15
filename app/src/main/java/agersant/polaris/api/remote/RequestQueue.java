package agersant.polaris.api.remote;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

class RequestQueue {

	private final OkHttpClient client;
	private final Auth auth;

	RequestQueue(Auth auth) {
		this.auth = auth;
		this.client = new OkHttpClient.Builder()
				.retryOnConnectionFailure(true)
				.authenticator(auth)
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

		Callback callbackWithAuth = new Callback() {
			@Override
			public void onFailure(Call call, IOException e) {
				callback.onFailure(call, e);
			}

			@Override
			public void onResponse(Call call, Response response) throws IOException {
				if (response.code() != 200) {
					callback.onFailure(call, null);
					return;
				}
				String setCookie = response.header("Set-Cookie", null);
				if (setCookie != null) {
					auth.parseCookie(setCookie);
				}
				callback.onResponse(call, response);
			}
		};

		client.newCall(request).enqueue(callbackWithAuth);
	}

}

