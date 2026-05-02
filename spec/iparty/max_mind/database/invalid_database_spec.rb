# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Database do
  each_reader_class do
    context "with missing database file" do
      it "raises error" do
        expect do
          IParty::MaxMind::Database.new(mmdb_directory.join("doesnotexist.mmdb"), reader: reader_class)
        end.to raise_error Errno::ENOENT
      end
    end

    context "with invalid database file" do
      it "raises error" do
        expect do
          IParty::MaxMind::Database.new(IPARTY_GEM_ROOT.join("spec", "spec_helper.rb"), reader: reader_class)
        end.to raise_error IParty::MaxMind::Database::InvalidFileFormatError
      end
    end
  end
end
