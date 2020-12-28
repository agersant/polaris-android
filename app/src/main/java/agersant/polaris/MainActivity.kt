package agersant.polaris

import agersant.polaris.databinding.ActivityMainBinding
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.NavController
import androidx.navigation.findNavController
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.AppBarConfiguration
import androidx.navigation.ui.setupActionBarWithNavController
import androidx.navigation.ui.setupWithNavController
import com.google.android.material.appbar.MaterialToolbar

class MainActivity : AppCompatActivity() {

    companion object {
        @JvmStatic
        lateinit var toolbar: MaterialToolbar
    }

    private lateinit var navController: NavController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val binding = ActivityMainBinding.inflate(layoutInflater)
        toolbar = binding.toolbar

        setContentView(binding.root)
        setSupportActionBar(binding.toolbar)

        val navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        navController = navHostFragment.navController

        val appBarConfiguration = AppBarConfiguration(
            setOf(
                R.id.nav_collection,
                R.id.nav_queue,
                R.id.nav_now_playing,
            )
        )

        setupActionBarWithNavController(navController, appBarConfiguration)
        binding.bottomNav.setupWithNavController(navController)

        navController.addOnDestinationChangedListener { _, _, _ ->
            toolbar.subtitle = ""
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        return navController.navigateUp() || super.onNavigateUp()
    }
}