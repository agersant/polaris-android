package agersant.polaris.features.browse;


import android.view.View;
import android.widget.TextView;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisService;
import agersant.polaris.R;

class BrowseItemHolderAlbumDiscHeader extends BrowseItemHolder {

	private final TextView textView;

	BrowseItemHolderAlbumDiscHeader(PolarisService service, BrowseAdapter adapter, View itemView, View itemQueueStatusView) {
		super(service, adapter, itemView, itemQueueStatusView);
		textView = (TextView) itemView.findViewById(R.id.disc);
	}

	@Override
	public void onClick(View view) {
		throw new UnsupportedOperationException();
	}

	@Override
	public void onSwiped(View view) {
		throw new UnsupportedOperationException();
	}

	@Override
	public void bindItem(CollectionItem item) {
		throw new UnsupportedOperationException();
	}

	void setDiscNumber(int number) {
		String displayText = itemView.getContext().getString(R.string.browse_disc_number, number);
		textView.setText(displayText);
	}
}
