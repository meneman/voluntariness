# Use this hook to configure the litestream-ruby gem.
# All configuration options will be available as environment variables, e.g.
# config.replica_bucket becomes LITESTREAM_REPLICA_BUCKET
# This allows you to configure Litestream using Rails encrypted credentials,
# or some other mechanism where the values are only available at runtime.

Rails.application.configure do
  # Configure Litestream through environment variables. Use Rails encrypted credentials for secrets.
  litestream_credentials = Rails.application.credentials.litestream

  # Replica-specific bucket location. This will be your bucket's URL without the `https://` prefix.
  # For example, if you used DigitalOcean Spaces, your bucket URL could look like:
  #
  #   https://myapp.fra1.digitaloceanspaces.com
  #
  # And so you should set your `replica_bucket` to:
  #
  #   myapp.fra1.digitaloceanspaces.com
  #
  config.litestream.replica_bucket = litestream_credentials&.replica_bucket || ENV["LITESTREAM_REPLICA_BUCKET"]

  # Replica-specific authentication key. Litestream needs authentication credentials to access your storage provider bucket.
  config.litestream.replica_key_id = litestream_credentials&.replica_key_id || ENV["LITESTREAM_ACCESS_KEY_ID"]

  # Replica-specific secret key. Litestream needs authentication credentials to access your storage provider bucket.
  config.litestream.replica_access_key = litestream_credentials&.replica_access_key || ENV["LITESTREAM_SECRET_ACCESS_KEY"]

  # Replica-specific region. Set the bucket's region. Only used for AWS S3 & Backblaze B2.
  config.litestream.replica_region = litestream_credentials&.replica_region || ENV["LITESTREAM_REPLICA_REGION"] || "us-east-1"
  
  # Replica-specific endpoint. Set the endpoint URL of the S3-compatible service. Only required for non-AWS services.
  # config.litestream.replica_endpoint = litestream_credentials&.replica_endpoint || ENV['LITESTREAM_REPLICA_ENDPOINT']

  # Configure the default Litestream config path
  config.litestream.config_path = Rails.root.join("config", "litestream.yml")

  # Configure the Litestream dashboard
  #
  # Set the default base controller class
  # config.litestream.base_controller_class = "ApplicationController"
  #
  # Set authentication credentials for Litestream dashboard
  config.litestream.username = litestream_credentials&.username || ENV["LITESTREAM_USERNAME"]
  config.litestream.password = litestream_credentials&.password || ENV["LITESTREAM_PASSWORD"]
end
