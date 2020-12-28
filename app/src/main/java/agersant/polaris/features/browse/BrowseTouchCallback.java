package agersant.polaris.features.browse;

import android.graphics.Canvas;

import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;


class BrowseTouchCallback extends ItemTouchHelper.SimpleCallback {

    BrowseTouchCallback() {
        super(0, 0);
    }

    @Override
    public int getSwipeDirs(RecyclerView recyclerView, RecyclerView.ViewHolder viewHolder) {
        if (viewHolder instanceof BrowseItemHolderAlbumDiscHeader) {
            return 0;
        }
        return ItemTouchHelper.RIGHT;
    }

    @Override
    public boolean onMove(RecyclerView recyclerView, RecyclerView.ViewHolder viewHolder, RecyclerView.ViewHolder target) {
        return false;
    }

    @Override
    public void onSwiped(RecyclerView.ViewHolder viewHolder, int direction) {
        BrowseItemHolder itemHolder = (BrowseItemHolder) viewHolder;
        itemHolder.onSwiped(itemHolder.itemView);
    }

    @Override
    public void onChildDraw(Canvas canvas, RecyclerView recyclerView, RecyclerView.ViewHolder viewHolder, float dX, float dY, int actionState, boolean isCurrentlyActive) {
        BrowseItemHolder itemHolder = (BrowseItemHolder) viewHolder;
        itemHolder.onChildDraw(canvas, dX, actionState);
        super.onChildDraw(canvas, recyclerView, viewHolder, dX, dY, actionState, isCurrentlyActive);
    }
}
