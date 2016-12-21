package agersant.polaris.features.browse;

import android.content.Context;
import android.content.Intent;
import android.graphics.Canvas;
import android.os.Handler;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import com.android.volley.Response;
import com.android.volley.VolleyError;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.ServerAPI;

/**
 * Created by agersant on 12/11/2016.
 */

abstract class BrowseItemHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

	private BrowseAdapter adapter;
	private CollectionItem item;
	private View queueStatusView;
	private TextView queueStatusText;
	private ImageView queueStatusIcon;

	BrowseItemHolder(BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
		super(itemView);
		this.adapter = adapter;
		queueStatusView = itemQueueStatusView;
		queueStatusText = (TextView) queueStatusView.findViewById(R.id.status_text);
		queueStatusIcon = (ImageView) queueStatusView.findViewById(R.id.status_icon);
	}

	void bindItem(CollectionItem item) {
		this.item = item;
		setStatusToQueueable();
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

	void onSwiped(final View view) {
		if (item.isDirectory()) {
			queueDirectory();
			setStatusToFetching();
		} else {
			Context context = view.getContext();
			PlaybackQueue.getInstance(context).addItem(item);
			setStatusToQueued();
		}
	}

	private void queueDirectory() {
		final Context context = itemView.getContext();
		final CollectionItem fetchingItem = item;

		Response.Listener<ArrayList<CollectionItem>> success = new Response.Listener<ArrayList<CollectionItem>>() {
			@Override
			public void onResponse(ArrayList<CollectionItem> response) {
				PlaybackQueue.getInstance(context).addItems(response);
				if (item == fetchingItem) {
					setStatusToQueued();
				}
			}
		};

		Response.ErrorListener failure = new Response.ErrorListener() {
			@Override
			public void onErrorResponse(VolleyError error) {
				if (item == fetchingItem) {
					setStatusToQueueError();
				}
			}
		};

		ServerAPI server = ServerAPI.getInstance(context);
		server.flatten(item.getPath(), success, failure);
	}

	private void setStatusToQueueable() {
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
		waitAndUnswipe();
	}

	private void setStatusToQueueError() {
		queueStatusText.setText(R.string.queuing_error);
		queueStatusIcon.setImageResource(R.drawable.ic_error_black_24dp);
		itemView.requestLayout();
		waitAndUnswipe();
	}

	private void waitAndUnswipe() {
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
			canvas.clipRect(0, 0, (int) dX, queueStatusView.getMeasuredHeight());
			queueStatusView.draw(canvas);
			canvas.restore();
		}
	}

}
