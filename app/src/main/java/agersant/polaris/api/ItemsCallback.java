package agersant.polaris.api;

import java.util.ArrayList;

import agersant.polaris.CollectionItem;

/**
 * Created by agersant on 5/6/2017.
 */

public interface ItemsCallback {

	void onSuccess(ArrayList<? extends CollectionItem> items);

	void onError();

}
