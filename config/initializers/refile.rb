# config/initializers/refile.rb
require "refile/s3"

aws = {
  access_key_id: ENV["AWS_ACCESS_KEY"],
  secret_access_key: ENV["AWS_SECRET_KEY"],
  region: "ap-southeast-2",
  bucket: "tennis-advantage-assets"
}
Refile.cache = Refile::S3.new(prefix: "cache", **aws)
Refile.store = Refile::S3.new(prefix: "store", **aws)
Refile.host = ENV["ASSET_HOST"]
