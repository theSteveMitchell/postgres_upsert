require "rails_helper"

describe PostgresUpsert do
  context "when passing ActiveRecord class as destination" do
    context "when passing ActiveRecord clas as Source" do
      let(:original_created_at) {5.days.ago.utc}

      before(:each) do
        TestModel.create(data: "From the before time, in the long long ago", :created_at => original_created_at)
      end

      it "copies the source to destination" do
          PostgresUpsert.write TestModelCopy, TestModel
          expect(
            TestModelCopy.first.attributes
          ).to eq(TestModelCopy.first.attributes)
      end

      context "with a large table" do
        before do
          csv_string = CSV.generate do |csv|
            csv << %w(id data)    # CSV header row
            (1..100_000).each do |n|
              csv << ["#{n}", "data about #{n}"]
            end
          end
          io = StringIO.new(csv_string)
          PostgresUpsert.write TestModel, io
        end

        it "moves like the poop through a goose" do
          expect{
            PostgresUpsert.write TestModelCopy, TestModel
          }.to change{TestModelCopy.count}.by(100_000)

        end
      end
    end
  end
end