#!/usr/bin/env ruby

require_relative '../lib/config.rb'
require "test/unit"

ENV["HOSTNAME"] ||= "ci"
ENV["TAILNET_IP"] = "1.2.3.4"

class ConfigTest < Test::Unit::TestCase
  def test_parses_config_once
    assert Config.instance
  end

  def test_parses_config_after_generating_templates
    assert Config.instance.generate_templated_files!
    assert Config.reload!
  end
end
