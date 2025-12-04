require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable Action Controller caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.variant_processor = :mini_magick

  # Add this line to specify the Active Storage service
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false

  # Email configuration for development
  # Use custom logger delivery method to show verification links in terminal
  config.action_mailer.delivery_method = :logger
  config.action_mailer.logger = Logger.new(STDOUT)

  # Alternative: Use letter_opener for browser preview (comment out logger above and uncomment below)
  # config.action_mailer.delivery_method = :letter_opener

  # Set default URL options for mailer
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # Bullet configuration for N+1 query detection
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true

    # Bullet whitelist - Safelists for ActiveStorage and model associations
    # User profile image (not always displayed but loaded for availability check)
    Bullet.add_safelist type: :unused_eager_loading, class_name: "User", association: :profile_image_attachment

    # Property photos N+1 prevention
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Property", association: :photos_attachments

    # ActiveStorage associations - Rails' with_attached_* scope loads these internally
    # These are false positives because Rails loads them to generate URLs/variants
    Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :blob
    Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Blob", association: :variant_records
    Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Blob", association: :preview_image_attachment

    # Property associations that may be loaded but not always used in all contexts
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Property", association: :user

    # PropertyComment replies - loaded for display but not always shown
    Bullet.add_safelist type: :unused_eager_loading, class_name: "PropertyComment", association: :replies
  end

  # Rack Mini Profiler configuration
  config.after_initialize do
    # Enable Rack Mini Profiler (must come after Bullet)
    Rack::MiniProfiler.config.position = "bottom-right"
    Rack::MiniProfiler.config.start_hidden = true
    Rack::MiniProfiler.config.enable_advanced_debugging_tools = true
  end
end
