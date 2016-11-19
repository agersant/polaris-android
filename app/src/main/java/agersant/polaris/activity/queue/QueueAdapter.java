package agersant.polaris.activity.queue;

import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;


class QueueAdapter extends RecyclerView.Adapter<QueueAdapter.QueueItemHolder> {

    private PlaybackQueue queue;

    QueueAdapter(PlaybackQueue queue) {
        super();
        this.queue = queue;
    }

    @Override
    public QueueAdapter.QueueItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View inflatedView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.queue_item, parent, false);
        return new QueueAdapter.QueueItemHolder(inflatedView);
    }

    @Override
    public void onBindViewHolder(QueueAdapter.QueueItemHolder holder, int position) {
        holder.bindItem(queue.getItem(position));
    }

    @Override
    public int getItemCount() {
        return queue.size();
    }

    static class QueueItemHolder extends RecyclerView.ViewHolder {

        private CollectionItem item;
        private TextView primaryText;
        private TextView secondaryText;

        QueueItemHolder(View view) {
            super(view);
            primaryText = (TextView) view.findViewById(R.id.primary_text);
            secondaryText = (TextView) view.findViewById(R.id.secondary_text);
        }

        void bindItem(CollectionItem item) {
            this.item = item;
            primaryText.setText(item.getTitle());
            secondaryText.setText(item.getArtist());
        }

    }
}
