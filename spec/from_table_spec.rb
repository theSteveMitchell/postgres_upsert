require "rails_helper"

describe PostgresUpsert do
  context "when passing ActiveRecord class as destination" do
    context "when passing ActiveRecord clas as Source" do
      let(:original_created_at) {5.days.ago.utc}

      before(:each) do
        TestModel.create(id: 1, data: "From the before time, in the long long ago", :created_at => original_created_at)
      end

      it "copies the source to destination" do
          PostgresUpsert.write TestModelCopy, TestModel
          expect(
            TestModelCopy.first.attributes
          ).to eq(TestModelCopy.first.attributes)
      end
    end
  end
end