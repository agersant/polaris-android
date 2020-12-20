package agersant.polaris;

import android.app.Application;
import android.content.Intent;
import android.content.SharedPreferences;

import androidx.appcompat.app.AppCompatDelegate;
import androidx.preference.PreferenceManager;

import agersant.polaris.ui.Theme;


public class PolarisApplication extends Application {

    private static PolarisApplication instance;

    private static PolarisState state;

    public static PolarisApplication getInstance() {
        assert instance != null;
        return instance;
    }

    public static PolarisState getState() {
        assert state != null;
        return state;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        state = new PolarisState(this);

        Intent playbackServiceIntent = new Intent(this, PolarisPlaybackService.class);
        playbackServiceIntent.setAction(PolarisPlaybackService.APP_INTENT_COLD_BOOT);
        startService(playbackServiceIntent);

        startService(new Intent(this, PolarisDownloadService.class));

        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
        String themeKey = getResources().getString(R.string.pref_key_theme);
        setTheme(preferences.getString(themeKey, ""));
    }

    public void setTheme(String value) {
        Theme theme;
        try {
            theme = Theme.valueOf(value);
        } catch (IllegalArgumentException e) {
            theme = Theme.System;
        }

        switch (theme) {
            case System:
                AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM);
                break;
            case Light:
                AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO);
                break;
            case Dark:
                AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES);
                break;
        }
    }

}
