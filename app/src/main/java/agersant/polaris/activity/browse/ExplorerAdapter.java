package agersant.polaris.activity.browse;

import android.os.Build;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;

import java.util.ArrayList;

import agersant.polaris.R;


class ExplorerAdapter extends RecyclerView.Adapter<ExplorerAdapter.BrowseItemHolder> {

    private ArrayList<ExplorerItem> items;
    private BrowseActivity browseActivity;

    ExplorerAdapter(BrowseActivity browseActivity) {
        this.browseActivity = browseActivity;
        setItems(new ArrayList<ExplorerItem>());
    }

    void setItems(ArrayList<ExplorerItem> items) {
        this.items = items;
        notifyDataSetChanged();
    }

    @Override
    public ExplorerAdapter.BrowseItemHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View inflatedView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.browse_explorer_item, parent, false);
        return new BrowseItemHolder(inflatedView, browseActivity);
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
        private ExplorerItem item;
        private BrowseActivity browseActivity;

        BrowseItemHolder(View view, BrowseActivity browseActivity) {
            super(view);
            this.browseActivity = browseActivity;
            button = (Button) view.findViewById(R.id.browse_explorer_button);
            button.setOnClickListener(this);
        }

        void bindItem(ExplorerItem item) {
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
            if (item.isDirectory()) {
                browseActivity.browseTo(item.getPath());
            }
        }
    }
}
