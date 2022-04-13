require "rubygems"
require "bundler/setup"
require "dotenv/load"
require "aws-sdk-s3"

task :publish do
  # Connect to S3 API.
  raise "SPACES_SECRET is not defined" if !ENV.has_key?("SPACES_SECRET")
  client = Aws::S3::Client.new(
    access_key_id: "LVQGQW47ER7IZFSPFZIM",
    secret_access_key: ENV["SPACES_SECRET"],
    endpoint: "https://fra1.digitaloceanspaces.com",
    region: "fra1"
  )
  # Pushing files.
  Dir.children("#{__dir__}/src").each do |filename|
    puts "Pushing #{filename}..."
    client.put_object({
      bucket: "pyrsmk",
      key: "run_extensions/#{filename}",
      body: File.read("#{__dir__}/src/#{filename}"),
      acl: "public-read"
    })
  end
  puts "Published."
end
