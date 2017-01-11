package agersant.polaris.api.remote;

import com.android.volley.AuthFailureError;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.HttpHeaderParser;
import com.android.volley.toolbox.JsonArrayRequest;
import com.android.volley.toolbox.RequestFuture;
import com.android.volley.toolbox.StringRequest;

import org.json.JSONArray;

import java.io.IOException;
import java.net.URLConnection;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

class Auth {

	private static final Pattern setCookiePattern = Pattern.compile("^(.*);");
	private ServerAPI serverAPI;
	private String cookie;

	Auth(ServerAPI serverAPI) {
		this.serverAPI = serverAPI;
		this.cookie = null;
	}

	private static Response<String> parseAuthResponse(NetworkResponse networkResponse) {
		String setCookie = networkResponse.headers.get("Set-Cookie");
		Matcher matcher = setCookiePattern.matcher(setCookie);
		if (!matcher.find()) {
			return Response.error(new VolleyError("No session cookie in response"));
		}
		String sessionID = matcher.group(1);
		assert sessionID != null;
		return Response.success(sessionID, HttpHeaderParser.parseCacheHeaders(networkResponse));
	}

	void doJsonArrayRequest(String requestURL, Response.Listener<JSONArray> success, Response.ErrorListener failure) {
		final Auth that = this;
		JsonArrayRequest request = new JsonArrayRequest(requestURL, success, failure) {
			public Map<String, String> getHeaders() throws AuthFailureError {
				HashMap<String, String> map = new HashMap<>();
				map.put("Cookie", that.cookie);
				return map;
			}
		};
		doRequest(request);
	}

	private void doRequest(final Request userRequest) {
		final Auth that = this;
		if (cookie == null) {
			doAsyncAuthRequest(new Response.Listener<String>() {
				@Override
				public void onResponse(String response) {
					that.doUserRequest(userRequest);
				}
			}, userRequest.getErrorListener());
		} else {
			this.doUserRequest(userRequest);
		}
	}

	private void doUserRequest(final Request userRequest) {
		assert this.cookie != null;
		this.serverAPI.getRequestQueue().addRequest(userRequest);
	}

	URLConnection connect(String url) throws InterruptedException, ExecutionException, TimeoutException, IOException {
		if (cookie == null) {
			cookie = doSyncAuthRequest();
		}
		URLConnection connection = new java.net.URL(url).openConnection();
		connection.setRequestProperty("Cookie", this.cookie);
		return connection;
	}

	private String getAuthRequestURL() {
		String serverAddress = this.serverAPI.getURL();
		return serverAddress + "/auth";
	}

	private String doSyncAuthRequest() throws InterruptedException, ExecutionException, TimeoutException {
		String requestURL = getAuthRequestURL();
		RequestFuture<String> future = RequestFuture.newFuture();
		StringRequest request = new StringRequest(Request.Method.POST, requestURL, future, future) {
			@Override
			protected Map<String, String> getParams() {
				return getAuthParams();
			}

			@Override
			protected Response<String> parseNetworkResponse(NetworkResponse networkResponse) {
				return Auth.parseAuthResponse(networkResponse);
			}
		};
		this.serverAPI.getRequestQueue().addRequest(request);
		return future.get(10, TimeUnit.SECONDS);
	}

	private void doAsyncAuthRequest(final Response.Listener<String> success, final Response.ErrorListener failure) {

		final Auth that = this;
		String requestURL = getAuthRequestURL();

		StringRequest request = new StringRequest(Request.Method.POST, requestURL, new Response.Listener<String>() {
			@Override
			public void onResponse(String response) {
				that.cookie = response;
				success.onResponse(response);
			}
		}, failure) {
			@Override
			protected Map<String, String> getParams() {
				return getAuthParams();
			}

			@Override
			protected Response<String> parseNetworkResponse(NetworkResponse networkResponse) {
				return Auth.parseAuthResponse(networkResponse);
			}
		};

		this.serverAPI.getRequestQueue().addRequest(request);
	}

	private Map<String, String> getAuthParams() {
		Map<String, String> params = new HashMap<>();
		params.put("username", serverAPI.getUsername());
		params.put("password", serverAPI.getPassword());
		return params;
	}

	String getCookie() {
		return cookie;
	}
}
