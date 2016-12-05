package agersant.polaris.activity.queue;

import android.os.Bundle;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;

import java.util.Random;

import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.activity.PolarisActivity;
import agersant.polaris.ui.DragAndSwipeTouchHelperCallback;

public class QueueActivity extends PolarisActivity {

    private QueueAdapter adapter;

    public QueueActivity() {
        super(R.string.queue, R.id.nav_queue);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_queue);
        super.onCreate(savedInstanceState);

        adapter = new QueueAdapter(PlaybackQueue.getInstance(this));

        RecyclerView recyclerView = (RecyclerView) findViewById(R.id.queue_recycler_view);
        recyclerView.setHasFixedSize(true);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);

        ItemTouchHelper.Callback callback = new DragAndSwipeTouchHelperCallback(adapter);
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(callback);
        itemTouchHelper.attachToRecyclerView(recyclerView);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.menu_queue, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.action_clear:
                clear();
                return true;
            case R.id.action_shuffle:
                shuffle();
                return true;
            case R.id.action_ordering_sequence:
            case R.id.action_ordering_repeat_one:
            case R.id.action_ordering_repeat_all:
            case R.id.action_ordering_random:
                setOrdering(item);
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    private void clear() {
        PlaybackQueue queue = PlaybackQueue.getInstance(this);
        int oldCount = adapter.getItemCount();
        queue.clear();
        adapter.notifyItemRangeRemoved(0, oldCount);
    }

    private void shuffle() {
        Random rng = new Random();
        PlaybackQueue queue = PlaybackQueue.getInstance(this);
        int count = adapter.getItemCount();
        for (int i = 0; i <= count - 2; i++) {
            int j = i + rng.nextInt(count - i);
            queue.move(i, j);
            adapter.notifyItemMoved(i, j);
        }
    }

    private void setOrdering(MenuItem item) {
        PlaybackQueue queue = PlaybackQueue.getInstance(this);
        switch (item.getItemId()) {
            case R.id.action_ordering_sequence:
                queue.setOrdering(PlaybackQueue.Ordering.SEQUENCE);
                break;
            case R.id.action_ordering_repeat_one:
                queue.setOrdering(PlaybackQueue.Ordering.REPEAT_ONE);
                break;
            case R.id.action_ordering_repeat_all:
                queue.setOrdering(PlaybackQueue.Ordering.REPEAT_ALL);
                break;
            case R.id.action_ordering_random:
                queue.setOrdering(PlaybackQueue.Ordering.RANDOM);
                break;
        }
        updateOrderingIcon();
    }

    private void updateOrderingIcon() {
        PlaybackQueue queue = PlaybackQueue.getInstance(this);
        int icon = getIconForOrdering(queue.getOrdering());
        MenuItem orderingItem = toolbar.getMenu().findItem(R.id.action_ordering);
        orderingItem.setIcon(icon);
    }

    private int getIconForOrdering(PlaybackQueue.Ordering ordering) {
        switch (ordering) {
            case REPEAT_ONE:
                return R.drawable.ic_repeat_one_black_24dp;
            case REPEAT_ALL:
                return R.drawable.ic_repeat_black_24dp;
            case RANDOM:
                return R.drawable.ic_shuffle_black_24dp;
            case SEQUENCE:
            default:
                return R.drawable.ic_reorder_black_24dp;
        }
    }
}