package agersant.polaris.api;


import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.android.volley.Response;
import com.android.volley.VolleyError;

import org.json.JSONArray;

import agersant.polaris.R;

public class ServerAPI {

    private static ServerAPI instance;
    private RequestQueue requestQueue;
    private SharedPreferences preferences;
    private Auth auth;

    private String serverAddressKey;
    private String usernameKey;
    private String passwordKey;

    private ServerAPI(Context context) {
        this.requestQueue = RequestQueue.getInstance(context);
        this.preferences = PreferenceManager.getDefaultSharedPreferences(context);
        this.auth = new Auth(this);

        serverAddressKey = context.getString(R.string.pref_key_server_url);
        usernameKey = context.getString(R.string.pref_key_username);
        passwordKey = context.getString(R.string.pref_key_password);
    }

    public static synchronized ServerAPI getInstance(Context context) {
        if (instance == null) {
            instance = new ServerAPI(context);
        }
        return instance;
    }

    public String getURL() {
        String address = this.preferences.getString(serverAddressKey, "");
        address = address.replaceAll("/$", "");
        return address + "/api";
    }

    String getUsername() {
        return this.preferences.getString(usernameKey, "");
    }

    String getPassword() {
        return this.preferences.getString(passwordKey, "");
    }

    RequestQueue getRequestQueue() {
        return this.requestQueue;
    }

    public String getAuthCookie() {
        return auth.getCookie();
    }

    public String getMediaURL(String path) {
        String serverAddress = this.getURL();
        return serverAddress + "/serve/" + path;
    }

    public void browse(String path, Response.Listener<JSONArray> success) {

        String serverAddress = this.getURL();
        String requestURL = serverAddress + "/browse/" + path;

        Response.ErrorListener failure = new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                // TODO Handle
                System.out.println("sadness here " + error);
            }
        };

        this.auth.doJsonArrayRequest(requestURL, success, failure);
    }
}

