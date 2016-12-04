package agersant.polaris.api;


import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.android.volley.Response;
import com.android.volley.VolleyError;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
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

    public void browse(String path, final Response.Listener<ArrayList<CollectionItem>> success) {
        String serverAddress = this.getURL();
        String requestURL = serverAddress + "/browse/" + path;
        Response.ErrorListener failure = new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                // TODO Handle
                System.out.println("browse sadness here " + error);
            }
        };

        Response.Listener successWrapper = new Response.Listener<JSONArray>() {
            @Override
            public void onResponse(JSONArray response) {
                ArrayList<CollectionItem> items = new ArrayList<>(response.length());
                for (int i = 0; i < response.length(); i++) {
                    try {
                        JSONObject item = response.getJSONObject(i);
                        CollectionItem browseItem = CollectionItem.parse(item);
                        items.add(browseItem);
                    } catch (Exception e) {
                    }
                }
                success.onResponse(items);
            }
        };

        this.auth.doJsonArrayRequest(requestURL, successWrapper, failure);
    }

    public void flatten(String path, final Response.Listener<ArrayList<CollectionItem>> success) {
        String serverAddress = this.getURL();
        String requestURL = serverAddress + "/flatten/" + path;

        Response.ErrorListener failure = new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError error) {
                // TODO Handle
                System.out.println("flatten sadness here " + error);
            }
        };

        Response.Listener successWrapper = new Response.Listener<JSONArray>() {
            @Override
            public void onResponse(JSONArray response) {
                ArrayList<CollectionItem> items = new ArrayList<>(response.length());
                for (int i = 0; i < response.length(); i++) {
                    try {
                        JSONObject item = response.getJSONObject(i);
                        CollectionItem browseItem = CollectionItem.parseSong(item);
                        items.add(browseItem);
                    } catch (Exception e) {
                    }
                }
                success.onResponse(items);
            }
        };

        this.auth.doJsonArrayRequest(requestURL, successWrapper, failure);
    }
}

