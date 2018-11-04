package agersant.polaris.features.browse;

import android.content.Context;
import android.content.Intent;
import android.graphics.Canvas;
import android.os.Handler;
import android.os.Looper;
import androidx.recyclerview.widget.RecyclerView;
import androidx.recyclerview.widget.ItemTouchHelper;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.API;
import agersant.polaris.api.ItemsCallback;


abstract class BrowseItemHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

	private final BrowseAdapter adapter;
	private CollectionItem item;
	private final View queueStatusView;
	private final TextView queueStatusText;
	private final ImageView queueStatusIcon;
	protected final PlaybackQueue playbackQueue;
	protected final API api;

	BrowseItemHolder(API api, PlaybackQueue playbackQueue, BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
		super(itemView);
		this.adapter = adapter;
		this.playbackQueue = playbackQueue;
		this.api = api;
		queueStatusView = itemQueueStatusView;
		queueStatusText = queueStatusView.findViewById(R.id.status_text);
		queueStatusIcon = queueStatusView.findViewById(R.id.status_icon);
	}

	void bindItem(CollectionItem item) {
		this.item = item;
		setStatusToIdle();
	}

	@Override
	public void onClick(View view) {
		Context context = view.getContext();
		if (item.isDirectory()) {
			Intent intent = new Intent(context, BrowseActivity.class);
			intent.putExtra(BrowseActivity.NAVIGATION_MODE, BrowseActivity.NavigationMode.PATH);
			intent.putExtra(BrowseActivity.PATH, item.getPath());
			intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
			context.startActivity(intent);
		}
	}

	@SuppressWarnings("UnusedParameters")
	void onSwiped(final View view) {
		if (item.isDirectory()) {
			queueDirectory();
			setStatusToFetching();
		} else {
			playbackQueue.addItem(item);
			setStatusToQueued();
		}
	}

	private void queueDirectory() {
		final CollectionItem fetchingItem = item;
		ItemsCallback handlers = new ItemsCallback() {
			@Override
			public void onSuccess(final ArrayList<? extends CollectionItem> items) {
				new Handler(Looper.getMainLooper()).post(new Runnable() {
					@Override
					public void run() {
						playbackQueue.addItems(items);
						if (item == fetchingItem) {
							setStatusToQueued();
						}
					}
				});
			}

			@Override
			public void onError() {
				new Handler(Looper.getMainLooper()).post(new Runnable() {
					@Override
					public void run() {
						if (item == fetchingItem) {
							setStatusToQueueError();
						}
					}
				});
			}
		};

		api.flatten(item.getPath(), handlers);
	}

	private void setStatusToIdle() {
		queueStatusText.setText(R.string.add_to_queue);
		queueStatusIcon.setImageResource(R.drawable.ic_playlist_play_black_24dp);
		itemView.requestLayout();
	}

	private void setStatusToFetching() {
		queueStatusText.setText(R.string.queuing);
		queueStatusIcon.setImageResource(R.drawable.ic_hourglass_empty_black_24dp);
		itemView.requestLayout();
	}

	private void setStatusToQueued() {
		queueStatusText.setText(R.string.queued);
		queueStatusIcon.setImageResource(R.drawable.ic_check_black_24dp);
		itemView.requestLayout();
		waitAndSwipeBack();
	}

	private void setStatusToQueueError() {
		queueStatusText.setText(R.string.queuing_error);
		queueStatusIcon.setImageResource(R.drawable.ic_error_black_24dp);
		itemView.requestLayout();
		waitAndSwipeBack();
	}

	private void waitAndSwipeBack() {
		final CollectionItem oldItem = item;
		final Handler handler = new Handler();
		handler.postDelayed(new Runnable() {
			@Override
			public void run() {
				if (item == oldItem) {
					int position = getAdapterPosition();
					adapter.notifyItemChanged(position);
				}
			}
		}, 1000);
	}

	void onChildDraw(Canvas canvas, float dX, int actionState) {
		if (actionState == ItemTouchHelper.ACTION_STATE_SWIPE) {
			int widthSpec = View.MeasureSpec.makeMeasureSpec(itemView.getWidth(), View.MeasureSpec.EXACTLY);
			int heightSpec = View.MeasureSpec.makeMeasureSpec(itemView.getHeight(), View.MeasureSpec.EXACTLY);
			queueStatusView.measure(widthSpec, heightSpec);
			queueStatusView.layout(0, 0, queueStatusView.getMeasuredWidth(), queueStatusView.getMeasuredHeight());

			canvas.save();
			canvas.translate(itemView.getLeft(), itemView.getTop());
			canvas.clipRect(0, 0, (int) Math.ceil(dX), queueStatusView.getMeasuredHeight());
			queueStatusView.draw(canvas);
			canvas.restore();
		}
	}

}
