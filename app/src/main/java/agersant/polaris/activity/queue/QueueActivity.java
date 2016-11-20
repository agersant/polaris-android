package agersant.polaris.activity.queue;

import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;

import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.activity.PolarisActivity;
import agersant.polaris.ui.DragAndSwipeTouchHelperCallback;

public class QueueActivity extends PolarisActivity {

    public QueueActivity() {
        super(R.string.queue, R.id.nav_queue);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_queue);
        super.onCreate(savedInstanceState);

        QueueAdapter adapter = new QueueAdapter(PlaybackQueue.getInstance(this));

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.queue_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);

        ItemTouchHelper.Callback callback = new DragAndSwipeTouchHelperCallback(adapter);
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);
    }
}
