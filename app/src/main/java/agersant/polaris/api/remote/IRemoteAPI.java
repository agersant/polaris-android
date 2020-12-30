package agersant.polaris.api.remote;

import android.net.Uri;

import java.io.IOException;

import agersant.polaris.api.IPolarisAPI;
import agersant.polaris.api.ItemsCallback;
import okhttp3.ResponseBody;

public interface IRemoteAPI extends IPolarisAPI {

    void getRandomAlbums(ItemsCallback handlers);

    void getRecentAlbums(ItemsCallback handlers);

    void setLastFMNowPlaying(String path);

    void scrobbleOnLastFM(String path);

    Uri getAudioUri(String path);

    Uri getThumbnailUri(String path);

    ResponseBody getAudio(String path) throws IOException;

    ResponseBody getThumbnail(String path) throws IOException;
}
