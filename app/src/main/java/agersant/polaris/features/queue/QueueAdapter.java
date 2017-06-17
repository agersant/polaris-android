package agersant.polaris.features.queue;

import android.os.AsyncTask;
import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import junit.framework.Assert;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;


class QueueAdapter
		extends RecyclerView.Adapter<QueueAdapter.QueueItemHolder> {

	private final PolarisService service;

	QueueAdapter(PolarisService service) {
		super();
		setHasStableIds(true);
		this.service = service;
	}

	@Override
	public QueueAdapter.QueueItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
		QueueItemView queueItemView = new QueueItemView(parent.getContext());
		return new QueueAdapter.QueueItemHolder(queueItemView, service);
	}

	@Override
	public void onBindViewHolder(QueueAdapter.QueueItemHolder holder, int position) {
		holder.bindItem(service.getItem(position));
	}

	@Override
	public long getItemId(int position) {
		CollectionItem item = service.getItem(position);
		return item.getPath().hashCode();
	}

	@Override
	public int getItemCount() {
		return service.size();
	}

	void onItemMove(int fromPosition, int toPosition) {
		service.swap(fromPosition, toPosition);
		notifyItemMoved(fromPosition, toPosition);
	}

	void onItemDismiss(int position) {
		service.remove(position);
		notifyItemRemoved(position);
	}

	static class QueueItemHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

		private final QueueItemView queueItemView;
		private final TextView titleText;
		private final TextView artistText;
		private final ImageView cacheIcon;
		private final ImageView downloadIcon;
		private final PolarisService service;
		private CollectionItem item;
		private QueueItemState state;
		private AsyncTask<Void, Void, QueueItemState> updateIconTask;

		QueueItemHolder(QueueItemView queueItemView, PolarisService service) {
			super(queueItemView);
			this.queueItemView = queueItemView;
			this.service = service;
			titleText = (TextView) queueItemView.findViewById(R.id.title);
			artistText = (TextView) queueItemView.findViewById(R.id.artist);
			cacheIcon = (ImageView) queueItemView.findViewById(R.id.cache_icon);
			downloadIcon = (ImageView) queueItemView.findViewById(R.id.download_icon);
			queueItemView.setOnClickListener(this);
		}

		private void beginIconUpdate() {
			Assert.assertNull(updateIconTask);
			final QueueItemHolder that = this;
			final CollectionItem item = this.item;

			updateIconTask = new AsyncTask<Void, Void, QueueItemState>() {
				@Override
				protected QueueItemState doInBackground(Void... objects) {
					if (service.isDownloading(item) || service.isStreaming(item)) {
						return QueueItemState.DOWNLOADING;
					} else if (service.hasLocalAudio(item)) {
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

			boolean isPlaying = service.getCurrentItem() == item;
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
			service.play(item);
		}
	}

	private enum QueueItemState {
		IDLE,
		DOWNLOADING,
		DOWNLOADED,
	}
}
