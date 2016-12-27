package agersant.polaris.api.remote;

import android.content.Context;

import com.android.volley.Request;
import com.android.volley.toolbox.Volley;

class RequestQueue {

	private static RequestQueue instance;
	private com.android.volley.RequestQueue requestQueue;

	private RequestQueue(Context context) {
		this.requestQueue = Volley.newRequestQueue(context);
	}

	static synchronized RequestQueue getInstance(Context context) {
		if (instance == null) {
			instance = new RequestQueue(context);
		}
		return instance;
	}

	<T> void addRequest(Request<T> req) {
		this.requestQueue.add(req);
	}

}

