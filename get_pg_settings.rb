require 'json'
require 'optparse'

require 'pg'

DEFAULT_SETTINGS_PATH = 'postgres_settings.json'.freeze
DEFAULT_DATABASE_URL = 'postgres://@/postgres'.freeze

NEON_SPECIFIC_SETTINGS = %w(
  lsn_cache_size
  enable_seqscan_prefetch
  seqscan_prefetch_buffers
).freeze

settings = nil

options = {
  path: DEFAULT_SETTINGS_PATH,
  database_url: DEFAULT_DATABASE_URL
}
OptionParser.new do |parser|
  parser.banner = "Usage: get_pg_settings.rb [options]"

  parser.on("-pPATH", "--path=PATH", "Result json path") do |p|
    options[:path] = p
  end
  parser.on("-dDATABASE_URL", "--database-url=DATABASE_URL", "Postgres DATABASE_URL") do |d|
    options[:database_url] = d
  end
end.parse!

# Get a list of pg_settings from the Postgres database and
# save as json file to the specified output path.
query = "
  SELECT name,
          context,
          vartype,
          unit,
          min_val,
          max_val,
          enumvals,
          category,
          short_desc
  FROM pg_settings
  ORDER BY name;
"

puts "Connecting to #{options[:database_url]}"
conn = PG::Connection.new(options[:database_url])
settings = conn.exec(query).to_a

settings.sort_by!{ |op| op['name'] }.map! do |op|
  if op['enumvals']
    op['enumvals'] = op['enumvals'][1..-2] # trim `{` and `}`
                      .split(',')
                      .each { |ev| ev.delete! '\"' }
  end

  # Tag implicitly everything that starts with `neon` as Neon specific
  if op['name'].start_with?('neon') ||
    NEON_SPECIFIC_SETTINGS.include?(op['name'])
    op['category'] = "Neon: #{op['category']}"
  end

  op
end

puts "Writing settings to #{options[:path]}"
File.open(options[:path], 'w') do |f|
  f.write(JSON.pretty_generate(settings))
end

puts "Done"
