package agersant.polaris.api.remote;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import agersant.polaris.R;

class Auth {

	private static final Pattern setCookiePattern = Pattern.compile("^(.*);");
	private SharedPreferences preferences;
	private String cookie;

	private String usernameKey;
	private String passwordKey;

	Auth(Context context) {
		this.preferences = PreferenceManager.getDefaultSharedPreferences(context);
		usernameKey = context.getString(R.string.pref_key_username);
		passwordKey = context.getString(R.string.pref_key_password);
		this.cookie = null;
	}

	String getCookie() {
		return this.cookie;
	}

	void parseCookie(String header) {
		Matcher matcher = setCookiePattern.matcher(header);
		if (matcher.find()) {
			this.cookie = matcher.group(1);
		}
	}

	String getAuthorizationHeader() {
		String username = preferences.getString(usernameKey, "");
		String password = preferences.getString(passwordKey, "");
		return username + ":" + password;
	}
}
