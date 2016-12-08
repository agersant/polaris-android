package agersant.polaris.activity.browse;

import android.content.Context;
import android.content.Intent;
import android.graphics.Canvas;
import android.os.Build;
import android.os.Handler;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import com.android.volley.Response;
import com.android.volley.VolleyError;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.ServerAPI;


public class ExplorerAdapter
        extends RecyclerView.Adapter<ExplorerAdapter.BrowseItemHolder> {

    private ArrayList<CollectionItem> items;

    public ExplorerAdapter() {
        setItems(new ArrayList<CollectionItem>());
    }

    public void setItems(ArrayList<CollectionItem> items) {
        this.items = items;
        notifyDataSetChanged();
    }

    @Override
    public ExplorerAdapter.BrowseItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View itemView = LayoutInflater.from(parent.getContext()).inflate(R.layout.browse_explorer_item, parent, false);
        View itemQueueStatusView = LayoutInflater.from(parent.getContext()).inflate(R.layout.browse_explorer_item_queued, parent, false);
        return new BrowseItemHolder(this, itemView, itemQueueStatusView);
    }

    @Override
    public void onBindViewHolder(ExplorerAdapter.BrowseItemHolder holder, int position) {
        holder.bindItem(items.get(position));
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    static class BrowseItemHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

        private ExplorerAdapter adapter;
        private Button button;
        private CollectionItem item;
        private View queueStatusView;
        private TextView queueStatusText;
        private ImageView queueStatusIcon;

        BrowseItemHolder(ExplorerAdapter adapter, View itemView, View itemQueueStatusView) {
            super(itemView);
            this.adapter = adapter;
            button = (Button) itemView.findViewById(R.id.browse_explorer_button);
            button.setOnClickListener(this);
            queueStatusView = itemQueueStatusView;
            queueStatusText = (TextView) queueStatusView.findViewById(R.id.status_text);
            queueStatusIcon = (ImageView) queueStatusView.findViewById(R.id.status_icon);
        }

        void bindItem(CollectionItem item) {
            this.item = item;
            button.setText(item.getName());

            int icon;
            if (item.isDirectory()) {
                icon = R.drawable.ic_folder_open_black_24dp;
            } else {
                icon = R.drawable.ic_audiotrack_black_24dp;
            }

            button.setCompoundDrawablesWithIntrinsicBounds(icon, 0, 0, 0);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                button.setCompoundDrawablesRelativeWithIntrinsicBounds(icon, 0, 0, 0);
            }

            setStatusToQueueable();
        }

        @Override
        public void onClick(View view) {
            Context context = view.getContext();
            if (item.isDirectory()) {
                Intent intent = new Intent(context, BrowseActivity.class);
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
}
