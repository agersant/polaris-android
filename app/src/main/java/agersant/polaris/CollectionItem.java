package agersant.polaris;

import org.json.JSONException;
import org.json.JSONObject;

public class CollectionItem implements Cloneable {

	private String name;
	private String path;
	private String artist;
	private String title;
	private String artwork;
	private String album;
	private Integer trackNumber;
	private boolean isDirectory;

	private CollectionItem() {
	}

	public static CollectionItem parse(JSONObject source) throws JSONException {
		CollectionItem item = new CollectionItem();
		item.isDirectory = source.optString("variant", "").equals("Directory");
		JSONObject fields = source.getJSONArray("fields").getJSONObject(0);
		item.parseFields(fields);
		return item;
	}

	public static CollectionItem parseSong(JSONObject fields) throws JSONException {
		CollectionItem item = new CollectionItem();
		item.isDirectory = false;
		item.parseFields(fields);
		return item;
	}

	private void parseFields(JSONObject fields) throws JSONException {
		path = fields.getString("path");
		artist = readStringField(fields, "artist");
		title = readStringField(fields, "title");
		artwork = readStringField(fields, "artwork");
		album = readStringField(fields, "album");
		trackNumber = readIntField(fields, "track_number");

		String[] chunks = path.split("/|\\\\");
		name = chunks[chunks.length - 1];
	}

	private String readStringField(JSONObject fields, String name) {

		String value = fields.optString(name);
		if (value != null && value.equals("null")) {
			return null;
		}
		return value;
	}

	private Integer readIntField(JSONObject fields, String name) throws JSONException {
		if (fields.isNull(name)) {
			return null;
		}
		return Integer.valueOf(fields.getInt(name));
	}

	@Override
	public CollectionItem clone() throws CloneNotSupportedException {
		return (CollectionItem) super.clone();
	}

	public String getName() {
		return name;
	}

	public String getPath() {
		return path;
	}

	public String getArtist() {
		return artist;
	}

	public String getTitle() {
		return title;
	}

	public String getArtwork() {
		return artwork;
	}

	public boolean isDirectory() {
		return isDirectory;
	}

	public String getAlbum() {
		return album;
	}

	public Integer getTrackNumber() {
		return trackNumber;
	}
}
