package agersant.polaris

import agersant.polaris.databinding.ActivityMainBinding
import agersant.polaris.navigation.setupWithNavController
import agersant.polaris.ui.BackdropLayout
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.LiveData
import androidx.navigation.NavController
import androidx.navigation.ui.AppBarConfiguration
import androidx.navigation.ui.setupWithNavController
import com.google.android.material.appbar.MaterialToolbar
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.android.material.navigation.NavigationView

class MainActivity : AppCompatActivity() {

    private lateinit var toolbar: MaterialToolbar
    private lateinit var backdropLayout: BackdropLayout
    private lateinit var backdropNav: NavigationView
    private lateinit var bottomNav: BottomNavigationView
    private var currentController: LiveData<NavController>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val binding = ActivityMainBinding.inflate(layoutInflater)
        toolbar = binding.toolbar
        backdropLayout = binding.backdropLayout
        backdropNav = binding.backdropNav
        bottomNav = binding.bottomNav


        setContentView(binding.root)
        setSupportActionBar(toolbar)
        supportActionBar?.setDisplayShowTitleEnabled(false)

        if (savedInstanceState == null) {
            setupNavigation()
        }
    }

    override fun onRestoreInstanceState(savedInstanceState: Bundle) {
        super.onRestoreInstanceState(savedInstanceState)

        setupNavigation()
    }

    override fun onSupportNavigateUp(): Boolean {
        return currentController?.value?.navigateUp() ?: false
    }

    private fun setupNavigation() {
        val navGraphIds = listOf(
            R.navigation.collection,
            R.navigation.queue,
            R.navigation.now_playing,
        )

        val navController = bottomNav.setupWithNavController(
            navGraphIds = navGraphIds,
            fragmentManager = supportFragmentManager,
            containerId = R.id.nav_host_fragment,
            intent = intent,
        )

        navController.observe(this) { controller ->
            val appBarConfiguration = AppBarConfiguration(
                setOf(
                    R.id.nav_collection,
                    R.id.nav_queue,
                    R.id.nav_now_playing,
                ),
                backdropLayout,
            )

            toolbar.setupWithNavController(controller, appBarConfiguration)
            backdropNav.setupWithNavController(controller)
            controller.addOnDestinationChangedListener { _, _, _ ->
                backdropLayout.close()
            }
        }

        // The NavigationExtension has no way to check if the deeplink was already handled so we remove the intent after handling.
        if (intent.hasExtra(NavController.KEY_DEEP_LINK_INTENT)) {
            intent.removeExtra(NavController.KEY_DEEP_LINK_INTENT)
            intent.removeExtra("android-support-nav:controller:deepLinkIds")
        }
    }
}
