package agersant.polaris.activity.browse;

class ExplorerItem {

    private String name;
    private String path;

    ExplorerItem(String path) {
        this.name = path;
        this.path = path;
    }

    public String getName() {
        return name;
    }

    public String getPath() {
        return path;
    }
}
