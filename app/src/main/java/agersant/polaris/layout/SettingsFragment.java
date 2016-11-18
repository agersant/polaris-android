package agersant.polaris.layout;


import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.Preference;
import android.preference.PreferenceFragment;

import agersant.polaris.R;

public class SettingsFragment extends PreferenceFragment implements SharedPreferences.OnSharedPreferenceChangeListener {

    public SettingsFragment() {
    }

    private SharedPreferences getSharedPreferences() {
        return getPreferenceManager().getSharedPreferences();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        addPreferencesFromResource(R.xml.preferences);
        getSharedPreferences().registerOnSharedPreferenceChangeListener(this);
    }

    @Override
    public void onResume() {
        super.onResume();
        for (String key : getSharedPreferences().getAll().keySet()) {
            Preference preference = this.findPreference(key);
            updatePreferenceSummary(preference, key);
        }
    }

    @Override
    public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key) {
        updatePreferenceSummary(findPreference(key), key);
    }

    private void updatePreferenceSummary(Preference preference, String key) {
        if (preference == null) {
            return;
        }
        preference.setSummary(getSharedPreferences().getString(key, ""));
    }
}
