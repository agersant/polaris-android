package agersant.polaris.api.remote;

import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DataSpec;
import com.google.android.exoplayer2.upstream.DefaultDataSource;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.upstream.HttpDataSource;
import com.google.android.exoplayer2.upstream.TransferListener;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.net.HttpURLConnection;
import java.util.BitSet;

import agersant.polaris.CollectionItem;
import agersant.polaris.PolarisApplication;
import agersant.polaris.api.local.OfflineCache;


public final class PolarisExoPlayerDataSourceFactory implements DataSource.Factory {

    private final PolarisExoPlayerHttpDataSource dataSource;

    PolarisExoPlayerDataSourceFactory(OfflineCache offlineCache, Auth auth, File scratchLocation, CollectionItem item) {
        PolarisExoPlayerHttpDataSourceFactory dataSourceFactory = new PolarisExoPlayerHttpDataSourceFactory(offlineCache, auth, scratchLocation, item);
        dataSource = dataSourceFactory.createDataSource();
    }

    @Override
    public DefaultDataSource createDataSource() {
        return new DefaultDataSource(PolarisApplication.getInstance().getApplicationContext(), dataSource);
    }

    private class PolarisExoPlayerTransferListener implements TransferListener {

        @Override
        public void onTransferInitializing(DataSource source, DataSpec dataSpec, boolean isNetwork) {
        }


        @Override
        public void onTransferStart(DataSource source, DataSpec dataSpec, boolean isNetwork) {

        }

        @Override
        public void onBytesTransferred(DataSource source, DataSpec dataSpec, boolean isNetwork, int bytesTransferred) {

        }

        @Override
        public void onTransferEnd(DataSource source, DataSpec dataSpec, boolean isNetwork) {
            PolarisExoPlayerHttpDataSource ds = (PolarisExoPlayerHttpDataSource) source;
            ds.onTransferEnd();
        }
    }

    private class PolarisExoPlayerHttpDataSource extends DefaultHttpDataSource {

        private final File scratchLocation;
        private final OfflineCache offlineCache;
        private final CollectionItem item;
        private BitSet bytesStreamed;
        private RandomAccessFile file;

        PolarisExoPlayerHttpDataSource(OfflineCache offlineCache, RequestProperties requestProperties, PolarisExoPlayerTransferListener listener, File scratchLocation, CollectionItem item) {
            super("Polaris Android", DEFAULT_CONNECT_TIMEOUT_MILLIS, DEFAULT_READ_TIMEOUT_MILLIS, true, requestProperties); //TODO: use factory instead of deprecated constructor
            addTransferListener(listener);
            this.scratchLocation = scratchLocation;
            this.offlineCache = offlineCache;
            this.item = item;
        }

        @Override
        public int read(byte[] buffer, int offset, int readLength) throws HttpDataSourceException {
            final int out = super.read(buffer, offset, readLength);
            if (out <= 0) {
                return out;
            }

            HttpURLConnection connection = getConnection();
            if (connection == null) {
                return out;
            }

            int length = connection.getContentLength();
            if (length <= 0) {
                return out;
            }

            if (bytesStreamed == null) {
                bytesStreamed = new BitSet(length);
                try {
                    if (scratchLocation.exists()) {
                        if (!scratchLocation.delete()) {
                            throw new IOException("Could not cleanse stream scratch location: " + scratchLocation);
                        }
                    }
                    file = new RandomAccessFile(scratchLocation, "rw");
                } catch (Exception e) {
                    System.out.println("Error while opening stream file: " + e);
                }
            }

            if (file == null) {
                return out;
            }

            int readStart = (int) (bytesRead() + bytesSkipped()) - out;
            bytesStreamed.set(readStart, readStart + out);

            try {
                file.write(buffer, offset, out);
            } catch (Exception e) {
                System.out.println("Error while writing audio to stream file: " + e);
                file = null;
            }

            if (bytesStreamed.nextClearBit(0) >= length) {
                System.out.println("Streaming complete, saving file for local use: " + item.getPath());
                try {
                    file.close();
                } catch (Exception e) {
                    System.out.println("Error while closing stream audio file: " + e);
                }
                file = null;

                try (FileInputStream scratchFile = new FileInputStream(scratchLocation)) {
                    offlineCache.putAudio(item, scratchFile);
                } catch (Exception e) {
                    System.out.println("Error while saving stream audio in offline cache: " + e);
                }
            }

            return out;
        }

        void onTransferEnd() {
            try {
                if (file != null) {
                    file.close();
                    file = null;
                }
            } catch (Exception e) {
                System.out.println("Error while closing stream file (cleanup): " + e);
            }
        }
    }

    private class PolarisExoPlayerHttpDataSourceFactory implements DataSource.Factory {

        final OfflineCache offlineCache;
        final Auth auth;
        final CollectionItem item;
        final File scratchLocation;

        PolarisExoPlayerHttpDataSourceFactory(OfflineCache offlineCache, Auth auth, File scratchLocation, CollectionItem item) {
            this.offlineCache = offlineCache;
            this.auth = auth;
            this.scratchLocation = scratchLocation;
            this.item = item;
        }

        @Override
        public PolarisExoPlayerHttpDataSource createDataSource() {

            HttpDataSource.RequestProperties requestProperties = new HttpDataSource.RequestProperties();
            String authCookie = auth.getCookieHeader();
            if (authCookie != null) {
                requestProperties.set("Cookie", authCookie);
            } else {
                String authRaw = auth.getAuthorizationHeader();
                requestProperties.set("Authorization", authRaw);
            }

            return new PolarisExoPlayerHttpDataSource(offlineCache, requestProperties, new PolarisExoPlayerTransferListener(), scratchLocation, item);
        }
    }
}
