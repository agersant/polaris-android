package agersant.polaris.features.settings;

import agersant.polaris.R;
import androidx.preference.EditTextPreference;
import androidx.preference.Preference;


public class PasswordSummaryProvider implements Preference.SummaryProvider<EditTextPreference> {

    @Override
    public CharSequence provideSummary(EditTextPreference preference) {
        String summary = preference.getText();

        if (summary == null || summary.isEmpty()) {
            return preference.getContext().getString(R.string.not_set);
        } else {
            @SuppressWarnings("ReplaceAllDot")
            String password = preference.getText().replaceAll(".", "*");
            return password;
        }
    }
}
