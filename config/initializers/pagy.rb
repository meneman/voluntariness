# Pagy configuration
require "pagy/extras/bootstrap"

# Configure Pagy defaults
Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:size] = [ 1, 2, 2, 1 ]

# Custom CSS classes for modern styling
Pagy::DEFAULT[:bootstrap_nav_class] = "flex items-center space-x-1"
Pagy::DEFAULT[:bootstrap_nav_class_link] = "inline-flex items-center px-3 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-md hover:bg-slate-50 dark:hover:bg-slate-600 hover:text-slate-900 dark:hover:text-white transition-colors duration-200"
Pagy::DEFAULT[:bootstrap_nav_class_active] = "inline-flex items-center px-3 py-2 text-sm font-medium text-white bg-blue-600 border border-blue-600 rounded-md"
Pagy::DEFAULT[:bootstrap_nav_class_prev] = "inline-flex items-center px-3 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-l-md hover:bg-slate-50 dark:hover:bg-slate-600 hover:text-slate-900 dark:hover:text-white transition-colors duration-200"
Pagy::DEFAULT[:bootstrap_nav_class_next] = "inline-flex items-center px-3 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 bg-white dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-r-md hover:bg-slate-50 dark:hover:bg-slate-600 hover:text-slate-900 dark:hover:text-white transition-colors duration-200"
