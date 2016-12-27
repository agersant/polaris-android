package agersant.polaris.api.remote;

import com.android.volley.AuthFailureError;
import com.android.volley.NetworkResponse;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.HttpHeaderParser;
import com.android.volley.toolbox.JsonArrayRequest;
import com.android.volley.toolbox.StringRequest;

import org.json.JSONArray;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

class Auth {

	private static final Pattern setCookiePattern = Pattern.compile("^(.*);");
	private ServerAPI serverAPI;
	private String cookie;

	Auth(ServerAPI serverAPI) {
		this.serverAPI = serverAPI;
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
			doAuthRequest(new Response.Listener<String>() {
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

	private void doAuthRequest(final Response.Listener<String> success, final Response.ErrorListener failure) {

		final Auth that = this;
		String serverAddress = this.serverAPI.getURL();
		String requestURL = serverAddress + "/auth";

		StringRequest request = new StringRequest(Request.Method.POST, requestURL, new Response.Listener<String>() {
			@Override
			public void onResponse(String response) {
				that.cookie = response;
				success.onResponse(response);
			}
		}, failure) {
			@Override
			protected Map<String, String> getParams() {
				Map<String, String> params = new HashMap<>();
				params.put("username", that.serverAPI.getUsername());
				params.put("password", that.serverAPI.getPassword());
				return params;
			}

			@Override
			protected Response<String> parseNetworkResponse(NetworkResponse networkResponse) {
				String setCookie = networkResponse.headers.get("Set-Cookie");
				Matcher matcher = setCookiePattern.matcher(setCookie);
				if (!matcher.find()) {
					return Response.error(new VolleyError("No session cookie in response"));
				}
				String sessionID = matcher.group(1);
				assert sessionID != null;
				return Response.success(sessionID, HttpHeaderParser.parseCacheHeaders(networkResponse));
			}
		};

		this.serverAPI.getRequestQueue().addRequest(request);
	}

	String getCookie() {
		return cookie;
	}
}
