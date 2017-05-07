package agersant.polaris.features.settings;


import android.content.SharedPreferences;
import android.content.res.Resources;
import android.os.Bundle;
import android.preference.Preference;
import android.preference.PreferenceFragment;

import java.util.Arrays;
import java.util.Map;

import agersant.polaris.R;

public class SettingsFragment extends PreferenceFragment implements SharedPreferences.OnSharedPreferenceChangeListener {

	private Resources resources;

	public SettingsFragment() {
	}

	private SharedPreferences getSharedPreferences() {
		return getPreferenceManager().getSharedPreferences();
	}

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		resources = getResources();
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
		Map<String, ?> all = getSharedPreferences().getAll();
		if (key.equals(resources.getString(R.string.pref_key_num_songs_preload))) {
			String[] entryValues = resources.getStringArray(R.array.pref_num_songs_preload_entry_values);
			String[] entries = resources.getStringArray(R.array.pref_num_songs_preload_entries);
			String entryValue = getSharedPreferences().getString(key, "");
			int selectedIndex = Arrays.asList(entryValues).indexOf(entryValue);
			String display = "";
			if (selectedIndex >= 0) {
				display = entries[selectedIndex];
			}
			preference.setSummary(display);
		} else if (key.equals(resources.getString(R.string.pref_key_offline_cache_size))) {
			String[] entryValues = resources.getStringArray(R.array.pref_offline_cache_size_entry_values);
			String[] entries = resources.getStringArray(R.array.pref_offline_cache_size_entries);
			String entryValue = getSharedPreferences().getString(key, "");
			int selectedIndex = Arrays.asList(entryValues).indexOf(entryValue);
			String display = "";
			if (selectedIndex >= 0) {
				display = entries[selectedIndex];
			}
			preference.setSummary(display);
		} else if (key.equals(resources.getString(R.string.pref_key_password))) {
			String password = getSharedPreferences().getString(key, "");
			String stars = password.replaceAll(".", "*");
			preference.setSummary(stars);
		} else if (all.get(key) instanceof String) {
			preference.setSummary(getSharedPreferences().getString(key, ""));
		}
	}
}
