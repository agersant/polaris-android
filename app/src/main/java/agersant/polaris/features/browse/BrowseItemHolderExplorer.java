package agersant.polaris.features.browse;

import android.os.Build;
import android.view.View;
import android.widget.Button;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;

/**
 * Created by agersant on 12/11/2016.
 */

class BrowseItemHolderExplorer extends BrowseItemHolder {

    private Button button;

    BrowseItemHolderExplorer(BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
        super(adapter, itemView, itemQueueStatusView);
        button = (Button) itemView.findViewById(R.id.browse_explorer_button);
        button.setOnClickListener(this);
    }

    @Override
    void bindItem(CollectionItem item) {
        super.bindItem(item);
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

}
