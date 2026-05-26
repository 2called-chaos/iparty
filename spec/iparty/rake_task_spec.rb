# frozen_string_literal: true

require "iparty/rake_task"

def clear_rake_namespace namespace
  tasks = Rake.application.instance_variable_get(:@tasks)
  expect(tasks.keys.none?{ _1.start_with?("#{namespace}:") }).to be true

  expect do
    yield(namespace)
  ensure
    tasks.delete_if{|name| name.start_with?("#{namespace}:") }
  end.to_not(change{ Rake.application.tasks.length })
end

RSpec.describe IParty::RakeTask do
  let(:iparty_tasks) { %w[update fetch status config] }

  context "with default namespace" do
    it "builds rake tasks" do
      clear_rake_namespace(:iparty) do
        IParty::RakeTask.new
        iparty_tasks.each {|name| expect(Rake.application.lookup("iparty:#{name}")).to be_a Rake::Task }
      end
    end
  end

  context "with custom namespace" do
    it "builds rake tasks" do
      clear_rake_namespace(:iparty_rspec) do
        IParty::RakeTask.new(:iparty_rspec)
        iparty_tasks.each {|name| expect(Rake.application.lookup("iparty_rspec:#{name}")).to be_a Rake::Task }
      end
    end

    it "yields" do
      clear_rake_namespace(:iparty_rspec) do
        IParty::RakeTask.new{|t| t.name = :iparty_rspec }
        iparty_tasks.each {|name| expect(Rake.application.lookup("iparty_rspec:#{name}")).to be_a Rake::Task }
      end
    end
  end

  describe "status task" do
    it "prints mmdb status" do
      clear_rake_namespace(:iparty) do
        IParty::RakeTask.new
        expect { Rake::Task["iparty:status"].invoke }.to output(/^(OK|MISSING|EXPIRED)/).to_stdout
      end
    end

    it "checks expired mmdb" do
      clear_rake_namespace(:iparty) do
        IParty::RakeTask.new
        expect do
          expect { Rake::Task["iparty:status"].invoke("1") }.to output(/^EXPIRED/).to_stdout
        end.to raise_error(SystemExit)
      end
    end
  end

  describe "config task" do
    it "pretty prints config" do
      clear_rake_namespace(:iparty) do
        IParty::RakeTask.new
        expect { Rake::Task["iparty:config"].invoke }.to output(/^\s+account_id: nil/).to_stdout
      end
    end

    it "prints config as json" do
      clear_rake_namespace(:iparty) do
        IParty::RakeTask.new
        expect { Rake::Task["iparty:config"].invoke("json") }.to output(/^{/).to_stdout
      end
    end

    it "prints config struct" do
      clear_rake_namespace(:iparty) do
        IParty::RakeTask.new
        expect { Rake::Task["iparty:config"].invoke("inspect") }.to output(/^#<struct IParty::Config/).to_stdout
      end
    end
  end
end
