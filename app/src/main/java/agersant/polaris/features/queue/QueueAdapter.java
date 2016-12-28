package agersant.polaris.features.queue;

import android.content.Context;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.Player;
import agersant.polaris.R;
import agersant.polaris.api.local.OfflineCache;


class QueueAdapter
		extends RecyclerView.Adapter<QueueAdapter.QueueItemHolder> {

	private PlaybackQueue queue;

	QueueAdapter(PlaybackQueue queue) {
		super();
		this.queue = queue;
	}

	@Override
	public QueueAdapter.QueueItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		QueueItemView queueItemView = new QueueItemView(parent.getContext());
		return new QueueAdapter.QueueItemHolder(queueItemView);
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
		private QueueItemView queueItemView;
		private TextView titleText;
		private TextView artistText;
		private ImageView cacheIcon;
		private Player player;

		QueueItemHolder(QueueItemView view) {
			super(view);
			queueItemView = view;
			player = Player.getInstance(view.getContext());
			titleText = (TextView) view.findViewById(R.id.title);
			artistText = (TextView) view.findViewById(R.id.artist);
			cacheIcon = (ImageView) view.findViewById(R.id.cache_icon);
			view.setOnClickListener(this);
		}

		void bindItem(CollectionItem item) {
			OfflineCache offlineCache = OfflineCache.getInstance();
			this.item = item;
			boolean isPlaying = player.getCurrentItem() == this.item;
			titleText.setText(item.getTitle());
			artistText.setText(item.getArtist());
			queueItemView.setIsPlaying(isPlaying);
			if (offlineCache.hasAudio(item.getPath())) {
				cacheIcon.setVisibility(View.VISIBLE);
			} else {
				cacheIcon.setVisibility(View.INVISIBLE);
			}
		}

		@Override
		public void onClick(View view) {
			Context context = view.getContext();
			Player.getInstance(context).play(item);
		}
	}
}
