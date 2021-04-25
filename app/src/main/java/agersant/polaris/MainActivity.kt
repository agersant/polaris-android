package agersant.polaris

import agersant.polaris.databinding.ActivityMainBinding
import agersant.polaris.navigation.setupWithNavController
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.LiveData
import androidx.lifecycle.observe
import androidx.navigation.NavController
import androidx.navigation.ui.AppBarConfiguration
import androidx.navigation.ui.setupWithNavController

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private var currentController: LiveData<NavController>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityMainBinding.inflate(layoutInflater)

        setContentView(binding.root)
        setSupportActionBar(binding.toolbar)
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

    fun setupNavigation() {
        val navGraphIds = listOf(
            R.navigation.collection,
            R.navigation.queue,
            R.navigation.now_playing,
        )

        val navController = binding.bottomNav.setupWithNavController(
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
                binding.backdropMenu,
            )

            binding.toolbar.setupWithNavController(controller, appBarConfiguration)
            binding.backdropNav.setupWithNavController(controller)
            binding.backdropMenu.setUpWith(controller, binding.toolbar)
            controller.addOnDestinationChangedListener { _, _, _ ->
                binding.toolbar.subtitle = ""
            }
        }

        // The NavigationExtension has no way to check if the deeplink was already handled so we remove the intent after handling.
        if (intent.hasExtra(NavController.KEY_DEEP_LINK_INTENT)) {
            intent.removeExtra(NavController.KEY_DEEP_LINK_INTENT)
            intent.removeExtra("android-support-nav:controller:deepLinkIds")
        }
    }
}
