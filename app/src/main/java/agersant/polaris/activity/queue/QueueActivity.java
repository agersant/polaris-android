package agersant.polaris.activity.queue;

import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;

import agersant.polaris.PlaybackQueue;
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

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.queue_recycler_view);
        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        recyclerView.setLayoutManager(linearLayoutManager);

        QueueAdapter adapter = new QueueAdapter(PlaybackQueue.getInstance());
        recyclerView.setAdapter(adapter);
    }
}
