package agersant.polaris.api.remote;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Base64;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import agersant.polaris.R;
import okhttp3.Interceptor;
import okhttp3.Request;
import okhttp3.Response;

class Auth implements Interceptor {

	private static final Pattern setCookiePattern = Pattern.compile("^(session=.*);");
	private final AtomicReference<String> syncCookie;
	private final SharedPreferences preferences;
	private final String usernameKey;
	private final String passwordKey;

	Auth(Context context) {
		this.syncCookie = new AtomicReference<>(null);
		this.preferences = PreferenceManager.getDefaultSharedPreferences(context);
		this.usernameKey = context.getString(R.string.pref_key_username);
		this.passwordKey = context.getString(R.string.pref_key_password);
	}

	String getCookieHeader() {
		return syncCookie.get();
	}

	String getAuthorizationHeader() {
		String username = preferences.getString(usernameKey, "");
		String password = preferences.getString(passwordKey, "");
		String credentials = username + ":" + password;
		return "Basic " + Base64.encodeToString(credentials.getBytes(), Base64.NO_WRAP);
	}

	private Request addAuthHeader(Request request) {
		String cookie = syncCookie.get();
		Request.Builder builder = request.newBuilder();
		builder.removeHeader("Cookie");
		builder.removeHeader("Authorization");
		if (cookie != null) {
			builder.header("Cookie", cookie);
		} else {
			builder.header("Authorization", getAuthorizationHeader());
		}
		return builder.build();
	}

	@Override public Response intercept(Interceptor.Chain chain) throws IOException {

		Request authRequest = addAuthHeader(chain.request());
		Response response = chain.proceed(authRequest);

		// Clear rejected cookie and retry
		String cookie = authRequest.header("Cookie");
		boolean hadCookie = cookie != null && !cookie.isEmpty();
		if (response.code() == 401 && hadCookie) {
			syncCookie.compareAndSet(cookie, null);
			return chain.proceed(addAuthHeader(chain.request()));
		}

		// Store new cookie
		List<String> setCookies = response.headers("Set-Cookie");
		for (String setCookie : setCookies) {
			Matcher matcher = setCookiePattern.matcher(setCookie);
			if (matcher.find()) {
				syncCookie.set(matcher.group(1));
				break;
			}
		}

		return response;
	}
}
