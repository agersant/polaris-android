package agersant.polaris;

import org.json.JSONObject;

public class CollectionItem implements Cloneable {

    private String name;
    private String path;
    private String artist;
    private String title;
    private String artwork;
    private boolean isDirectory;

    public CollectionItem(JSONObject source) {
        try {
            isDirectory = source.getString("variant").equals("Directory");
            JSONObject fields = source.getJSONArray("fields").getJSONObject(0);
            path = fields.getString("path");
            artist = fields.optString("artist", null);
            title = fields.optString("title", null);
            artwork = fields.optString("artwork", null);
        } catch (Exception e) {
            System.err.println("Unexpected CollectionItem structure: " + e.toString());
        }

        String[] chunks = path.split("/|\\\\");
        name = chunks[chunks.length - 1];
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
}
