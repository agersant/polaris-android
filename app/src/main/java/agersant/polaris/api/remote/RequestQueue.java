package agersant.polaris.api.remote;

import android.content.Context;
import android.util.Base64;

import java.io.IOException;

import okhttp3.Authenticator;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;
import okhttp3.Route;

public class RequestQueue {

	private static RequestQueue instance;
	private final OkHttpClient client;
	private final Auth auth;

	private RequestQueue(Context context) {
		this.auth = new Auth(context);
		this.client = new OkHttpClient.Builder()
				.retryOnConnectionFailure(true)
				.authenticator(new Authenticator() {
					@Override
					public Request authenticate(Route route, Response response) throws IOException {
						Request.Builder newRequest = response.request().newBuilder();
						String authCookie = auth.getCookie();
						if (authCookie != null) {
							newRequest.header("Cookie", authCookie);
						} else {
							String authorization = auth.getAuthorizationHeader();
							authorization = "Basic " + Base64.encodeToString(authorization.getBytes(), Base64.NO_WRAP);
							newRequest.header("Authorization", authorization);
						}
						return newRequest.build();
					}
				})
				.build();
	}

	public static void init(Context context) {
		instance = new RequestQueue(context);
	}

	static RequestQueue getInstance() {
		return instance;
	}

	ResponseBody requestSync(Request request) {
		Response response;
		try {
			response = client.newCall(request).execute();
		} catch (Exception e) {
			return null;
		}
		if (!response.isSuccessful()) {
			return null;
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
				if (auth.getCookie() == null) {
					String setCookie = response.header("Set-Cookie", null);
					if (setCookie != null) {
						auth.parseCookie(setCookie);
					}
				}
				callback.onResponse(call, response);
			}
		};

		client.newCall(request).enqueue(callbackWithAuth);
	}

}

