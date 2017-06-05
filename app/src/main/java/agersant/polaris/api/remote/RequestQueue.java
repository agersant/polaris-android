package agersant.polaris.api.remote;

import android.content.Context;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

public class RequestQueue {

	private static RequestQueue instance;
	private final OkHttpClient client;
	private final Auth auth;

	private RequestQueue(Context context) {
		this.auth = new Auth(context);
		this.client = new OkHttpClient.Builder()
				.retryOnConnectionFailure(true)
				.authenticator(auth)
				.build();
	}

	public static void init(Context context) {
		instance = new RequestQueue(context);
	}

	static RequestQueue getInstance() {
		return instance;
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

