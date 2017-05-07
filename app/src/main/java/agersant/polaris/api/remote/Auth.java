package agersant.polaris.api.remote;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Base64;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import agersant.polaris.R;
import okhttp3.Authenticator;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.Route;

class Auth implements Authenticator {

	private static final Pattern setCookiePattern = Pattern.compile("^(.*);");
	private SharedPreferences preferences;
	private String cookie;

	private String usernameKey;
	private String passwordKey;

	Auth(Context context) {
		preferences = PreferenceManager.getDefaultSharedPreferences(context);
		usernameKey = context.getString(R.string.pref_key_username);
		passwordKey = context.getString(R.string.pref_key_password);
		cookie = null;
	}

	void parseCookie(String header) {
		Matcher matcher = setCookiePattern.matcher(header);
		if (matcher.find()) {
			this.cookie = matcher.group(1);
		}
	}

	private String getAuthorizationHeader() {
		String username = preferences.getString(usernameKey, "");
		String password = preferences.getString(passwordKey, "");
		return username + ":" + password;
	}

	@Override
	public Request authenticate(Route route, Response response) throws IOException {
		Request.Builder newRequest = response.request().newBuilder();

		String oldCookie = response.request().header("Cookie");
		boolean newCookie = cookie != null && (oldCookie == null || !cookie.equals(oldCookie));
		if (newCookie) {
			newRequest.header("Cookie", cookie);
			return newRequest.build();
		}

		String authorization = getAuthorizationHeader();
		authorization = "Basic " + Base64.encodeToString(authorization.getBytes(), Base64.NO_WRAP);
		String oldAuthorization = response.request().header("Authorization");
		boolean newAuthorization = oldAuthorization == null || !authorization.equals(oldAuthorization);
		if (newAuthorization) {
			newRequest.header("Authorization", authorization);
			return newRequest.build();
		}

		return null;
	}
}
