package agersant.polaris.api.remote;

import android.net.Uri;
import android.os.AsyncTask;

import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.upstream.DataSpec;
import com.google.android.exoplayer2.upstream.DefaultDataSource;


class DownloadTask extends AsyncTask<Object, Integer, Integer> {

    private static final int BUFFER_SIZE = 1024 * 64; // 64 kB

    private final DefaultDataSource dataSource;
    private final DataSpec dataSpec;

    DownloadTask(DefaultDataSource dataSource, Uri uri) {
        this.dataSource = dataSource;
        dataSpec = new DataSpec(uri);
    }

    @Override
    protected Integer doInBackground(Object... params) {
        byte[] buffer = new byte[BUFFER_SIZE];
        try {
            dataSource.open(dataSpec);
            while (true) {
                if (isCancelled()) {
                    break;
                }
                int bytesRead = dataSource.read(buffer, 0, BUFFER_SIZE);
                if (bytesRead == 0 || bytesRead == C.RESULT_END_OF_INPUT) {
                    break;
                }
            }
        } catch (Exception e) {
            System.out.println("Download task error during reads: " + e + " (" + dataSpec.uri + ")");
        }

        try {
            dataSource.close();
        } catch (Exception e) {
            System.out.println("Download task error during close: " + e);
        }

        return 0;
    }

}
