package agersant.polaris.api;

public interface IPolarisAPI {

	void browse(String path, final ItemsCallback handlers);

	void flatten(String path, final ItemsCallback handlers);

}
