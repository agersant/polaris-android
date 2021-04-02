package agersant.polaris.features.browse;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import agersant.polaris.PolarisApplication;
import agersant.polaris.PolarisState;
import agersant.polaris.R;
import agersant.polaris.api.API;
import agersant.polaris.databinding.FragmentCollectionBinding;
import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.navigation.Navigation;


public class CollectionFragment extends Fragment {

    private FragmentCollectionBinding binding;
    private API api;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        setHasOptionsMenu(true);

        PolarisState state = PolarisApplication.getState();
        this.api = state.api;

        binding = FragmentCollectionBinding.inflate(inflater);

        binding.browseDirectories.setOnClickListener(this::browseDirectories);
        binding.randomAlbums.setOnClickListener(this::browseRandom);
        binding.recentAlbums.setOnClickListener(this::browseRecent);

        return binding.getRoot();
    }

    @Override
    public void onStart() {
        super.onStart();
        updateButtons();
    }

    @Override
    public void onResume() {
        super.onResume();
        updateButtons();
    }

    public void browseDirectories(View view) {
        Bundle args = new Bundle();
        args.putSerializable(BrowseFragment.NAVIGATION_MODE, BrowseFragment.NavigationMode.PATH);
        Navigation.findNavController(view).navigate(R.id.action_nav_collection_to_nav_browse, args);
    }

    public void browseRandom(View view) {
        Bundle args = new Bundle();
        args.putSerializable(BrowseFragment.NAVIGATION_MODE, BrowseFragment.NavigationMode.RANDOM);
        Navigation.findNavController(view).navigate(R.id.action_nav_collection_to_nav_browse, args);
    }

    public void browseRecent(View view) {
        Bundle args = new Bundle();
        args.putSerializable(BrowseFragment.NAVIGATION_MODE, BrowseFragment.NavigationMode.RECENT);
        Navigation.findNavController(view).navigate(R.id.action_nav_collection_to_nav_browse, args);
    }

    private void updateButtons() {
        boolean isOffline = api.isOffline();
        binding.randomAlbums.setEnabled(!isOffline);
        binding.recentAlbums.setEnabled(!isOffline);
    }
}
