package agersant.polaris.api;

import android.media.MediaDataSource;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

/**
 * Created by agersant on 12/26/2016.
 */

class StreamingMediaDataSource extends MediaDataSource {

	private File tempFile;
	private boolean completed;

	StreamingMediaDataSource(File tempFile) {
		super();
		this.tempFile = tempFile;
		completed = false;
	}

	void markAsComplete() {
		completed = true;
	}

	@Override
	public int readAt(long position, byte[] buffer, int offset, int size) throws IOException {
		FileInputStream input = null;
		try {

			input = new FileInputStream(tempFile);

			int skipped = 0;
			while (skipped < position) {
				skipped += input.skip(position);
			}

			int read = 0;
			while (read < size) {
				int bytes = input.read(buffer, offset, size);
				if (bytes > 0) {
					size -= bytes;
					read += bytes;
					offset += bytes;
				}
				if (bytes < 0 && completed) {
					break;
				}
			}

			input.close();
			return read;

		} catch (IOException e) {
			System.out.println("Streaming error: " + e);
		}

		if (input != null) {
			input.close();
		}

		// TODO can only get here from exception. should reach from file end
		return -1;
	}

	@Override
	public long getSize() throws IOException {
		return -1;
	}

	@Override
	public void close() throws IOException {
	}
}
