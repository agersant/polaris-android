package agersant.polaris.api.remote;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Base64;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicReference;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import agersant.polaris.R;
import okhttp3.Interceptor;
import okhttp3.Request;
import okhttp3.Response;

class Auth implements Interceptor {

	private static final Pattern setCookiePattern = Pattern.compile("^(.*);");
	private final AtomicReference<String> syncCookie;
	private final SharedPreferences preferences;
	private final String usernameKey;
	private final String passwordKey;

	Auth(Context context) {
		syncCookie = new AtomicReference<>(null);
		preferences = PreferenceManager.getDefaultSharedPreferences(context);
		usernameKey = context.getString(R.string.pref_key_username);
		passwordKey = context.getString(R.string.pref_key_password);
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

	private void parseCookie(String header) {
		Matcher matcher = setCookiePattern.matcher(header);
		if (matcher.find()) {
			syncCookie.set(matcher.group(1));
		}
	}

	@Override public Response intercept(Interceptor.Chain chain) throws IOException {

		Request request = chain.request();

		String cookie = syncCookie.get();
		if (cookie != null) {
			request = request.newBuilder().header("Cookie", cookie).build();
		} else {
			request = request.newBuilder().header("Authorization", getAuthorizationHeader()).build();
		}

		Response response = chain.proceed(request);

		// Clear rejected cookie and retry
		if (response.code() == 401 && cookie != null) {
			syncCookie.compareAndSet(cookie, null);
			return chain.proceed(response.request());
		}

		// Store new cookie
		String setCookie = response.header("Set-Cookie", null);
		if (setCookie != null) {
			parseCookie(setCookie);
		}

		return response;
	}
}
