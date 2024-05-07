require 'json'
require 'subprocess'
require 'sorbet-runtime'
require_relative './ds_logger'

class Secrets < T::Struct
  def self.load_all!

    return @secrets if defined? @secrets

    LOGGER.info('Secrets.load_all!')
    items_json = `op item list --format json --categories 'Secure Note,Server' --vault 'keen.land secrets' | op item get - --format json`

    all_items = items_json.split(%r[(?<=})\n(?={)]m).map do |item|
      JSON.parse(item)
    end

    servers = all_items.select { |i| i["category"] == "SERVER" }
    notes = all_items.select { |i| i["category"] == "SECURE_NOTE" }

    secrets_by_hostname = Hash.new { |h,k| h[k] = {} }

    servers.each do |server|
      notes.select { |n| (n["tags"]&.intersection(server["tags"])&.length || 0) > 0 }.each do |note|
        note["fields"].each do |field|
          next if field["label"] == "notesPlain"

          secrets_by_hostname[server["title"]][field["label"]] = field["value"]
        end
      end
    end

    @secrets = secrets_by_hostname
  end
end
