package agersant.polaris.features.queue;

import android.support.v7.widget.RecyclerView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;


class QueueAdapter
		extends RecyclerView.Adapter<QueueAdapter.QueueItemHolder> {

	private PolarisService service;

	QueueAdapter(PolarisService service) {
		super();
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

		private CollectionItem item;
		private QueueItemView queueItemView;
		private TextView titleText;
		private TextView artistText;
		private ImageView cacheIcon;
		private ImageView downloadIcon;
		private PolarisService service;

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

		void bindItem(CollectionItem item) {
			this.item = item;
			boolean isPlaying = service.getCurrentItem() == this.item;
			titleText.setText(item.getTitle());
			artistText.setText(item.getArtist());
			queueItemView.setIsPlaying(isPlaying);
			if (service.hasLocalAudio(item)) {
				cacheIcon.setVisibility(View.VISIBLE);
				downloadIcon.setVisibility(View.INVISIBLE);
			} else if (service.isDownloading(item)) {
				cacheIcon.setVisibility(View.INVISIBLE);
				downloadIcon.setVisibility(View.VISIBLE);
			} else {
				cacheIcon.setVisibility(View.INVISIBLE);
				downloadIcon.setVisibility(View.INVISIBLE);
			}
		}

		@Override
		public void onClick(View view) {
			service.play(item);
		}
	}
}
