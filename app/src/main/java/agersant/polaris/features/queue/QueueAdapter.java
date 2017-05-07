package agersant.polaris.features.queue;

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
import agersant.polaris.api.remote.DownloadQueue;


class QueueAdapter
		extends RecyclerView.Adapter<QueueAdapter.QueueItemHolder> {

	private PlaybackQueue playbackQueue;

	QueueAdapter(PlaybackQueue playbackQueue) {
		super();
		this.playbackQueue = playbackQueue;
	}

	@Override
	public QueueAdapter.QueueItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		QueueItemView queueItemView = new QueueItemView(parent.getContext());
		return new QueueAdapter.QueueItemHolder(queueItemView);
	}

	@Override
	public void onBindViewHolder(QueueAdapter.QueueItemHolder holder, int position) {
		holder.bindItem(playbackQueue.getItem(position));
	}

	@Override
	public int getItemCount() {
		return playbackQueue.size();
	}

	void onItemMove(int fromPosition, int toPosition) {
		playbackQueue.swap(fromPosition, toPosition);
		notifyItemMoved(fromPosition, toPosition);
	}

	void onItemDismiss(int position) {
		playbackQueue.remove(position);
		notifyItemRemoved(position);
	}

	static class QueueItemHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

		private CollectionItem item;
		private QueueItemView queueItemView;
		private TextView titleText;
		private TextView artistText;
		private ImageView cacheIcon;
		private ImageView downloadIcon;
		private Player player;

		QueueItemHolder(QueueItemView view) {
			super(view);
			queueItemView = view;
			player = Player.getInstance();
			titleText = (TextView) view.findViewById(R.id.title);
			artistText = (TextView) view.findViewById(R.id.artist);
			cacheIcon = (ImageView) view.findViewById(R.id.cache_icon);
			downloadIcon = (ImageView) view.findViewById(R.id.download_icon);
			view.setOnClickListener(this);
		}

		void bindItem(CollectionItem item) {
			OfflineCache offlineCache = OfflineCache.getInstance();
			DownloadQueue downloadQueue = DownloadQueue.getInstance();
			this.item = item;
			boolean isPlaying = player.getCurrentItem() == this.item;
			titleText.setText(item.getTitle());
			artistText.setText(item.getArtist());
			queueItemView.setIsPlaying(isPlaying);
			if (offlineCache.hasAudio(item.getPath())) {
				cacheIcon.setVisibility(View.VISIBLE);
				downloadIcon.setVisibility(View.INVISIBLE);
			} else if (downloadQueue.isWorkingOn(item)) {
				cacheIcon.setVisibility(View.INVISIBLE);
				downloadIcon.setVisibility(View.VISIBLE);
			} else {
				cacheIcon.setVisibility(View.INVISIBLE);
				downloadIcon.setVisibility(View.INVISIBLE);
			}
		}

		@Override
		public void onClick(View view) {
			Player.getInstance().play(item);
		}
	}
}
