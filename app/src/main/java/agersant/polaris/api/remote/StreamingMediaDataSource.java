package agersant.polaris.api.remote;

import android.media.MediaDataSource;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;

/**
 * Created by agersant on 12/26/2016.
 */

public class StreamingMediaDataSource extends MediaDataSource {

	private RandomAccessFile streamFile;
	private boolean completed;
	private int size;

	StreamingMediaDataSource(File streamFile) throws IOException {
		super();
		this.streamFile = new RandomAccessFile(streamFile, "r");
		completed = false;
		size = -1;
	}

	void markAsComplete() {
		completed = true;
	}

	void setContentLength(int length) {
		size = length;
	}

	@Override
	public int readAt(long position, byte[] buffer, int offset, int bytesToRead) throws IOException {
		try {

			streamFile.seek(position);

			int read = 0;
			while (read < bytesToRead) {
				int bytes = streamFile.read(buffer, offset, bytesToRead - read);
				if (bytes > 0) {
					read += bytes;
					offset += bytes;
				}
				if (bytes < 0 && completed) {
					if (read == 0) {
						return -1;
					} else {
						return read;
					}
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
		return size;
	}

	@Override
	public void close() throws IOException {
		streamFile.close();
	}
}
