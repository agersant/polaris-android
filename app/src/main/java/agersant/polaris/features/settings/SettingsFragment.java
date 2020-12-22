package agersant.polaris.features.settings;


import android.os.Bundle;

import androidx.preference.EditTextPreference;
import androidx.preference.ListPreference;
import androidx.preference.PreferenceFragmentCompat;

import agersant.polaris.PolarisApplication;
import agersant.polaris.R;


public class SettingsFragment extends PreferenceFragmentCompat {

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        setPreferencesFromResource(R.xml.preferences, rootKey);

        String passwordKey = getResources().getString(R.string.pref_key_password);
        EditTextPreference passwordPreference = findPreference(passwordKey);
        passwordPreference.setSummaryProvider(new PasswordSummaryProvider());

        String themeKey = getResources().getString(R.string.pref_key_theme);
        ListPreference themePreference = findPreference(themeKey);
        themePreference.setOnPreferenceChangeListener((preference, newValue) -> {
            if (newValue != null) {
                PolarisApplication.getInstance().setTheme(newValue.toString());
            }
            return true;
        });
    }
}
