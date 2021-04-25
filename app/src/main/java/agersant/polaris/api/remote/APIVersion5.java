package agersant.polaris.api.remote;

import android.net.Uri;

class APIVersion5 extends APIVersion4 {
    APIVersion5(DownloadQueue downloadQueue, RequestQueue requestQueue) {
        super(downloadQueue, requestQueue);
    }

    String getAudioURL(String path) {
        String serverAddress = ServerAPI.getAPIRootURL();
        return serverAddress + "/audio/" + Uri.encode(path);
    }

    String getThumbnailURL(String path) {
        String serverAddress = ServerAPI.getAPIRootURL();
        return serverAddress + "/thumbnail/" + Uri.encode(path);
    }
}
