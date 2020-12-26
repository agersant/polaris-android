package agersant.polaris.features.browse;

import android.view.View;

import com.google.android.material.button.MaterialButton;

import agersant.polaris.CollectionItem;
import agersant.polaris.PlaybackQueue;
import agersant.polaris.R;
import agersant.polaris.api.API;


class BrowseItemHolderExplorer extends BrowseItemHolder {

	private final MaterialButton button;

	BrowseItemHolderExplorer(API api, PlaybackQueue playbackQueue, BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
		super(api, playbackQueue, adapter, itemView, itemQueueStatusView);
		button = itemView.findViewById(R.id.browse_explorer_button);
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

		button.setIconResource(icon);
	}

}
