package agersant.polaris.api.remote;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;

/**
 * Created by agersant on 12/26/2016.
 */

public class StreamingMediaDataSource {

	private File sourceFile;
	private RandomAccessFile streamFile;

	StreamingMediaDataSource(File sourceFile) throws IOException {
		super();
		this.sourceFile = sourceFile;
		this.streamFile = new RandomAccessFile(sourceFile, "r");
	}

	File getFile() {
		return sourceFile;
	}

}
