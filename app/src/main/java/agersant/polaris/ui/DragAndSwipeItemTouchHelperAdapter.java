package agersant.polaris.ui;

public interface DragAndSwipeItemTouchHelperAdapter {
    void onItemMove(int fromPosition, int toPosition);

    void onItemDismiss(int position);
}