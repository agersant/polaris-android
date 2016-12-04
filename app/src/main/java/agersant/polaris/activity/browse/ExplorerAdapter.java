package agersant.polaris.activity.browse;

import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.os.Build;
import android.support.v7.widget.RecyclerView;
import android.support.v7.widget.helper.ItemTouchHelper;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;

import com.android.volley.Response;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.ServerAPI;


class ExplorerAdapter
        extends RecyclerView.Adapter<ExplorerAdapter.BrowseItemHolder> {

    private ArrayList<CollectionItem> items;

    ExplorerAdapter() {
        setItems(new ArrayList<CollectionItem>());
    }

    void setItems(ArrayList<CollectionItem> items) {
        this.items = items;
        notifyDataSetChanged();
    }

    @Override
    public ExplorerAdapter.BrowseItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View inflatedView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.browse_explorer_item, parent, false);
        return new BrowseItemHolder(inflatedView);
    }

    @Override
    public void onBindViewHolder(ExplorerAdapter.BrowseItemHolder holder, int position) {
        holder.bindItem(items.get(position));
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    public static class BrowseItemHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

        private Button button;
        private CollectionItem item;

        BrowseItemHolder(View view) {
            super(view);
            button = (Button) view.findViewById(R.id.browse_explorer_button);
            button.setOnClickListener(this);
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

        void onSwiped(View view) {
            final Context context = view.getContext();
            if (item.isDirectory()) {
                Response.Listener<ArrayList<CollectionItem>> success = new Response.Listener<ArrayList<CollectionItem>>() {
                    @Override
                    public void onResponse(ArrayList<CollectionItem> response) {
                        PlaybackQueue.getInstance(context).addItems(response);
                    }
                };
                ServerAPI server = ServerAPI.getInstance(context);
                server.flatten(item.getPath(), success);
            } else {
                PlaybackQueue.getInstance(context).addItem(item);
            }
        }

        void onChildDraw(Canvas c, float dX, int actionState) {
            Paint paint = new Paint();

            if (actionState == ItemTouchHelper.ACTION_STATE_SWIPE) {
                float left = itemView.getLeft() + itemView.getPaddingLeft();
                float top = itemView.getTop() + itemView.getPaddingTop();
                float bottom = itemView.getBottom() - itemView.getPaddingBottom();

                float height = bottom - top;
                float iconPadding = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 12, itemView.getResources().getDisplayMetrics());
                float iconSize = height - 2 * iconPadding;
                float iconLeft = left + iconPadding;
                float iconTop = top + (height - iconSize) / 2;

                if (dX > 0) {
                    paint.setColor(Color.parseColor("#388E3C"));
                    RectF background = new RectF(left, top, left + dX, bottom);
                    c.drawRect(background, paint);

                    Bitmap icon = BitmapFactory.decodeResource(itemView.getResources(), R.drawable.ic_folder_black_24dp);
                    RectF icon_dest = new RectF(iconLeft, iconTop, iconLeft + iconSize, iconTop + iconSize);
                    c.drawBitmap(icon, null, icon_dest, paint);
                }
            }
        }

    }
}
