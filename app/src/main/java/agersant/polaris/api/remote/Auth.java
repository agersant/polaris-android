package agersant.polaris.api.remote;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Base64;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import agersant.polaris.R;
import okhttp3.Authenticator;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.Route;

class Auth implements Authenticator {

	private static final Pattern setCookiePattern = Pattern.compile("^(.*);");
	private final SharedPreferences preferences;
	private final String usernameKey;
	private final String passwordKey;
	private String cookie;

	Auth(Context context) {
		preferences = PreferenceManager.getDefaultSharedPreferences(context);
		usernameKey = context.getString(R.string.pref_key_username);
		passwordKey = context.getString(R.string.pref_key_password);
		cookie = null;
	}

	public String getCookieHeader() {
		return cookie;
	}

	public String getAuthorizationHeader() {
		String username = preferences.getString(usernameKey, "");
		String password = preferences.getString(passwordKey, "");
		String credentials = username + ":" + password;
		return "Basic " + Base64.encodeToString(credentials.getBytes(), Base64.NO_WRAP);
	}

	void parseCookie(String header) {
		Matcher matcher = setCookiePattern.matcher(header);
		if (matcher.find()) {
			this.cookie = matcher.group(1);
		}
	}

	@Override
	public Request authenticate(Route route, Response response) {
		Request.Builder newRequest = response.request().newBuilder();

		String oldCookie = response.request().header("Cookie");
		boolean newCookie = cookie != null && !cookie.equals(oldCookie);
		if (newCookie) {
			newRequest.header("Cookie", cookie);
			return newRequest.build();
		}

		String authorization = getAuthorizationHeader();
		String oldAuthorization = response.request().header("Authorization");
		boolean newAuthorization = !authorization.equals(oldAuthorization);
		if (newAuthorization) {
			newRequest.header("Authorization", authorization);
			return newRequest.build();
		}

		return null;
	}
}
