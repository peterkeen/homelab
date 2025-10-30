# frozen_string_literal: true

require 'subprocess'
require 'singleton'
require 'tempfile'
require 'pstore'
require 'time'
require 'shellwords'
require 'json'

class Secrets
  include Singleton

  class Item
    def initialize(raw)
      @raw = raw
      map_fields(include_notes: true) do |field|
        if field["type"] == "SSHKEY"
          field["ssh_formats"]["openssh"].delete("value")
        end
        field.delete("value")
      end
    end

    def vars
      map_fields do |field|
        if field["type"] == "SSHKEY"
          [field["label"], field.dig("ssh_formats", "openssh", "value")]
        else
          [field["label"], field["value"]]
        end
      end.to_h
    end

    def refs
      map_fields do |field|
        [field["label"], field["reference"]]
      end.to_h
    end

    def obfuscated_refs
      vault = @raw["vault"]["id"]
      item_id = @raw["id"]

      map_fields do |field|
        field_id = field["id"]
        ref = "op://#{vault}/#{item_id}/#{field_id}"
        if field["type"] == "SSHKEY"
          ref = "#{ref}?ssh-format=openssh"
        end
        [field["label"], ref]
      end.to_h
    end

    def [](key)
      vars[key]
    end

    def updated_at
      DateTime.parse(@raw["updated_at"])
    end

    def map_fields(include_notes: false, &block)
      @raw["fields"].filter_map do |field|
        next if field["label"] == "notesPlain" unless include_notes
        yield field
      end
    end
  end

  def items_for_server(server)
    ids = @tags_by_server[server].flat_map do |tag|
      @items_by_tag[tag]
    end.sort.uniq

    fetch_items(ids)
  end

  def get(id)
    fetch_items([id]).first
  end

  private

  VAULT_UUID = "fmycvdzmeyvbndk7s7pjyrebtq"
  PSTORE_PATH = File.expand_path(File.join(__FILE__, '../../secrets.store'))
  PSTORE_ITEMS_LIST_KEY = "items_list"
  PSTORE_ITEMS_LIST_CACHE_TTL = 10

  def initialize
    @items = PStore.new(PSTORE_PATH)
    @items_by_tag = Hash.new {|h,k| h[k] = []}
    @tags_by_server = Hash.new {|h,k| h[k] = []}

    preload
  end

  def transaction(&block)
    @items.transaction do
      yield
    end
  end

  def preload
    transaction do
      items_list.each do |item|
        if @items.key?(item["id"])
          stored = @items[item["id"]]
          new_ts = DateTime.parse(item["updated_at"])

          @items.delete(item["id"]) if stored.updated_at < new_ts
        end

        if item["category"] == "SECURE_NOTE"
          item.fetch("tags", []).each do |tag|
            @items_by_tag[tag] << item["id"]
          end
        else
          @tags_by_server[item["title"]] = item["tags"]
        end
      end
    end
  end

  def items_list
    list = @items[PSTORE_ITEMS_LIST_KEY]
    if list.nil? || (list[:updated_at] + PSTORE_ITEMS_LIST_CACHE_TTL) < Time.now
      (@items[PSTORE_ITEMS_LIST_KEY] = {
        items: fetch_items_list,
        updated_at: Time.now
      })[:items]
    else
      list[:items]
    end
  end

  def fetch_items_list
    raw = Subprocess.check_output(Shellwords.split("op item list --format json --categories 'Secure Note,Server,SSH Key' --vault #{VAULT_UUID}"))
    JSON.parse(raw)
  end

  def fetch_items(ids)
    transaction do
      known_items = ids.filter_map { |id| next unless @items.key?(id); [id, @items[id]] }.to_h
      unknown_ids = (ids - known_items.keys).sort.uniq

      if unknown_ids.length == 0
        return known_items.values
      end

      fetch_json = unknown_ids.map do |id|
        {"id" => id, "vault" => {"id" => VAULT_UUID}}
      end

      items_json = nil
      Subprocess.check_call(%W{op item get - --format json}, stdin: Subprocess::PIPE, stdout: Subprocess::PIPE) do |p|
        stdout, _stderr = p.communicate(fetch_json.to_json)
        items_json = stdout
      end

      Subprocess.check_call(%W{jq -s}, stdin: Subprocess::PIPE, stdout: Subprocess::PIPE) do |p|
        stdout, _stderr = p.communicate(items_json)
        JSON.parse(stdout).each do |item|
          @items[item["id"]] = Item.new(item)
        end
      end

      ids.map { |id| @items[id] }
    end
  end

end
