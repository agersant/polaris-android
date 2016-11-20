package agersant.polaris.activity.browse;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;


class ExplorerAdapter extends RecyclerView.Adapter<ExplorerAdapter.BrowseItemHolder> {

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

    static class BrowseItemHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

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
            } else {
                PlaybackQueue.getInstance(context).add(item);
            }
        }
    }
}
