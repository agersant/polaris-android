package agersant.polaris.api;

import com.google.android.exoplayer2.source.MediaSource;

import java.io.IOException;

import agersant.polaris.CollectionItem;

public interface IPolarisAPI {

    MediaSource getAudio(CollectionItem item) throws IOException;

    void browse(String path, final ItemsCallback handlers);

    void flatten(String path, final ItemsCallback handlers);

}
