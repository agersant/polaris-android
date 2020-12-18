package agersant.polaris.features.settings;


import android.os.Bundle;

import androidx.preference.EditTextPreference;
import androidx.preference.PreferenceFragmentCompat;

import agersant.polaris.R;


public class SettingsFragment extends PreferenceFragmentCompat {

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        setPreferencesFromResource(R.xml.preferences, rootKey);

        String passwordKey = getResources().getString(R.string.pref_key_password);
        EditTextPreference passwordPreference = findPreference(passwordKey);
        passwordPreference.setSummaryProvider(new PasswordSummaryProvider());
    }
}
