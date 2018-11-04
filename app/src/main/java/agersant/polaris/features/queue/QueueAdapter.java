package agersant.polaris.features.queue;

import android.os.AsyncTask;
import androidx.recyclerview.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.PolarisPlayer;
import agersant.polaris.R;
import agersant.polaris.api.local.OfflineCache;
import agersant.polaris.api.remote.DownloadQueue;


class QueueAdapter
		extends RecyclerView.Adapter<QueueAdapter.QueueItemHolder> {

	private final PlaybackQueue playbackQueue;
	private final PolarisPlayer player;
	private final OfflineCache offlineCache;
	private final DownloadQueue downloadQueue;

	QueueAdapter(PlaybackQueue playbackQueue, PolarisPlayer player, OfflineCache offlineCache, DownloadQueue downloadQueue) {
		super();
		this.playbackQueue = playbackQueue;
		this.player = player;
		this.offlineCache = offlineCache;
		this.downloadQueue = downloadQueue;
	}

	@Override
	public QueueAdapter.QueueItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		QueueItemView queueItemView = new QueueItemView(parent.getContext());
		return new QueueAdapter.QueueItemHolder(queueItemView, player, offlineCache, downloadQueue);
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

		private final QueueItemView queueItemView;
		private final TextView titleText;
		private final TextView artistText;
		private final ImageView cacheIcon;
		private final ImageView downloadIcon;
		private final PolarisPlayer player;
		private final OfflineCache offlineCache;
		private final DownloadQueue downloadQueue;
		private CollectionItem item;
		private QueueItemState state;
		private AsyncTask<Void, Void, QueueItemState> updateIconTask;

		QueueItemHolder(QueueItemView queueItemView, PolarisPlayer player, OfflineCache offlineCache, DownloadQueue downloadQueue) {
			super(queueItemView);
			this.queueItemView = queueItemView;
			this.player = player;
			this.offlineCache = offlineCache;
			this.downloadQueue = downloadQueue;
			titleText = queueItemView.findViewById(R.id.title);
			artistText = queueItemView.findViewById(R.id.artist);
			cacheIcon = queueItemView.findViewById(R.id.cache_icon);
			downloadIcon = queueItemView.findViewById(R.id.download_icon);
			queueItemView.setOnClickListener(this);
		}

		private void beginIconUpdate() {
			final QueueItemHolder that = this;
			final CollectionItem item = this.item;

			updateIconTask = new AsyncTask<Void, Void, QueueItemState>() {
				@Override
				protected QueueItemState doInBackground(Void... objects) {
					if (downloadQueue.isDownloading(item) || downloadQueue.isStreaming(item)) {
						return QueueItemState.DOWNLOADING;
					} else if (offlineCache.hasAudio(item.getPath())) {
						return QueueItemState.DOWNLOADED;
					} else {
						return QueueItemState.IDLE;
					}
				}

				@Override
				protected void onPostExecute(QueueItemState state) {
					if (that.item != item) {
						return;
					}
					setState( state );
				}
			};

			updateIconTask.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
		}

		void bindItem(final CollectionItem item) {

			boolean isNewItem = item != this.item;
			this.item = item;

			if (isNewItem) {
				titleText.setText(item.getTitle());
				artistText.setText(item.getArtist());
				setState( QueueItemState.IDLE );
			}

			boolean isPlaying = player.getCurrentItem() == item;
			queueItemView.setIsPlaying(isPlaying);

			if (updateIconTask != null) {
				updateIconTask.cancel(true);
				updateIconTask = null;
			}

			beginIconUpdate();
		}

		private void setState(QueueItemState newState) {
			state = newState;
			switch (state) {
				case IDLE:
					cacheIcon.setVisibility(View.INVISIBLE);
					downloadIcon.setVisibility(View.INVISIBLE);
					break;
				case DOWNLOADING:
					cacheIcon.setVisibility(View.INVISIBLE);
					downloadIcon.setVisibility(View.VISIBLE);
					break;
				case DOWNLOADED:
					cacheIcon.setVisibility(View.VISIBLE);
					downloadIcon.setVisibility(View.INVISIBLE);
					break;
			}
		}

		@Override
		public void onClick(View view) {
			player.play(item);
		}
	}

	private enum QueueItemState {
		IDLE,
		DOWNLOADING,
		DOWNLOADED,
	}
}
