package agersant.polaris.features.queue;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.Player;
import agersant.polaris.R;


class QueueAdapter
        extends RecyclerView.Adapter<QueueAdapter.QueueItemHolder> {

    private PlaybackQueue queue;

    QueueAdapter(PlaybackQueue queue) {
        super();
        this.queue = queue;
    }

    @Override
    public QueueAdapter.QueueItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View inflatedView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.view_queue_item, parent, false);
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

    void onItemMove(int fromPosition, int toPosition) {
        queue.swap(fromPosition, toPosition);
        notifyItemMoved(fromPosition, toPosition);
    }

    void onItemDismiss(int position) {
        queue.remove(position);
        notifyItemRemoved(position);
    }

    static class QueueItemHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

        private CollectionItem item;
        private TextView titleText;
        private TextView artistText;

        QueueItemHolder(View view) {
            super(view);
            titleText = (TextView) view.findViewById(R.id.title);
            artistText = (TextView) view.findViewById(R.id.artist);
            view.setOnClickListener(this);
        }

        void bindItem(CollectionItem item) {
            this.item = item;
            titleText.setText(item.getTitle());
            artistText.setText(item.getArtist());
        }

        @Override
        public void onClick(View view) {
            Context context = view.getContext();
            Player.getInstance(context).play(item);
        }
    }
}
