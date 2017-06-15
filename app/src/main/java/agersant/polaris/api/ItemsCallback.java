package agersant.polaris.api;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;


public interface ItemsCallback {

	void onSuccess(ArrayList<? extends CollectionItem> items);

	void onError();

}
