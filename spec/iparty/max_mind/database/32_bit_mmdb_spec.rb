# frozen_string_literal: true

RSpec.describe IParty::MaxMind::Database do
  each_reader_class do
    let(:mmdb_directory) { IPARTY_GEM_ROOT.join("spec", "data") }

    context "with 32bit record data mmdb" do
      subject(:rec32_db) { IParty::MaxMind::Database.new(mmdb_directory.join("32bit_record_data.mmdb"), reader: reader_class) }

      let(:ip) { "1.0.16.1" }

      it "finds data" do
        expect(rec32_db.lookup(ip)).to_not be_empty
      end
    end
  end
end
