package agersant.polaris.activity.queue;

import android.os.Bundle;

import agersant.polaris.R;
import agersant.polaris.activity.PolarisActivity;

public class QueueActivity extends PolarisActivity {

    public QueueActivity() {
        super(R.string.queue, R.id.nav_queue);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_queue);
        super.onCreate(savedInstanceState);
    }
}
