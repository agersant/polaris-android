package agersant.polaris.api.remote;

import android.media.MediaDataSource;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;

/**
 * Created by agersant on 12/26/2016.
 */

class StreamingMediaDataSource extends MediaDataSource {

	private RandomAccessFile streamFile;
	private boolean completed;

	StreamingMediaDataSource(File streamFile) throws IOException {
		super();
		this.streamFile = new RandomAccessFile(streamFile, "r");
		completed = false;
	}

	void markAsComplete() {
		completed = true;
	}

	@Override
	public int readAt(long position, byte[] buffer, int offset, int size) throws IOException {
		try {

			streamFile.seek(position);
			int read = 0;
			while (read < size) {
				int bytes = streamFile.read(buffer, offset, size);
				if (bytes > 0) {
					size -= bytes;
					read += bytes;
					offset += bytes;
				}
				if (bytes < 0 && completed) {
					if (read == 0) {
						return -1;
					}
					break;
				}
			}

			return read;

		} catch (IOException e) {
			System.out.println("Streaming error: " + e);
		}

		return -1;
	}

	@Override
	public long getSize() throws IOException {
		return -1;
	}

	@Override
	public void close() throws IOException {
		streamFile.close();
	}
}
