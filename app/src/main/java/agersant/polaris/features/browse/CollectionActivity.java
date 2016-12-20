package agersant.polaris.features.browse;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import agersant.polaris.R;
import agersant.polaris.features.PolarisActivity;

public class CollectionActivity extends PolarisActivity {

	public CollectionActivity() {
		super(R.string.collection, R.id.nav_collection);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		setContentView(R.layout.activity_collection);
		super.onCreate(savedInstanceState);

		// Disable unimplemented features
		{
			Button button;
			button = (Button) findViewById(R.id.random);
			button.setEnabled(false);
			button = (Button) findViewById(R.id.recently_added);
			button.setEnabled(false);
			button = (Button) findViewById(R.id.playlists);
			button.setEnabled(false);
		}
	}

	public void browseDirectories(View view) {
		Context context = view.getContext();
		Intent showBrowser = new Intent(context, BrowseActivity.class);
		showBrowser.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
		context.startActivity(showBrowser);
	}
}
