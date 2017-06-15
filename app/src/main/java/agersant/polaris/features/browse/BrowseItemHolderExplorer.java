package agersant.polaris.features.browse;

import android.view.View;
import android.widget.Button;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;


class BrowseItemHolderExplorer extends BrowseItemHolder {

	private final Button button;

	BrowseItemHolderExplorer(PolarisService service, BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
		super(service, adapter, itemView, itemQueueStatusView);
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
		button.setCompoundDrawablesRelativeWithIntrinsicBounds(icon, 0, 0, 0);
	}

}
