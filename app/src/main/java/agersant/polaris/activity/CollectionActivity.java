package agersant.polaris.activity;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;

import agersant.polaris.R;
import agersant.polaris.activity.browse.BrowseActivity;

public class CollectionActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_collection);

        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        toolbar.setTitle(R.string.collection);
        setSupportActionBar(toolbar);

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

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.menu_main, menu);
        return true;
    }

    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_settings:
                Intent intent = new Intent(this, SettingsActivity.class);
                startActivity(intent);
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    public void browseDirectories(View view) {
        Context context = view.getContext();
        Intent showBrowser = new Intent(context, BrowseActivity.class);
        context.startActivity(showBrowser);
    }
}
