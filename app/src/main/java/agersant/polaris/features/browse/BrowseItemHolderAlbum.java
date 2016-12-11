package agersant.polaris.features.browse;

import android.view.View;
import android.widget.Button;

import agersant.polaris.CollectionItem;
import agersant.polaris.R;

/**
 * Created by agersant on 12/11/2016.
 */

public class BrowseItemHolderAlbum extends BrowseItemHolder {

    private Button button;

    BrowseItemHolderAlbum(BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
        super(adapter, itemView, itemQueueStatusView);
        button = (Button) itemView.findViewById(R.id.button);
        button.setOnClickListener(this);
    }

    @Override
    void bindItem(CollectionItem item) {
        super.bindItem(item);
        button.setText(item.getName());
    }

}
