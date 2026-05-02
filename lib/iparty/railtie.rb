# frozen_string_literal: true

module IParty
  class Railtie < Rails::Railtie
    railtie_name :iparty

    rake_tasks do
      require "iparty/rake_task"
      IParty::RakeTask.new
    end

    config.before_configuration do
      IParty.config.directory = IParty.env_value("IPARTY_DIRECTORY", nil) do |dir|
        if dir && !dir.empty?
          Pathname.new(dir)
        else
          Rails.root.join("vendor", "maxmind")
        end
      end
    end
  end
end
