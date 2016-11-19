package agersant.polaris.activity.queue;

import android.os.Bundle;

import agersant.polaris.R;
import agersant.polaris.activity.PolarisActivity;

public class QueueActivity extends PolarisActivity {

    QueueActivity() {
        super(R.string.queue);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_queue);
        super.onCreate(savedInstanceState);
    }
}
