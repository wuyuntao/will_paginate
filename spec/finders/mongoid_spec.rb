require 'spec_helper'
require 'will_paginate/mongoid'

Mongoid.database = Mongo::Connection.new.db('will_paginate_test')

class MongoidModel
  include Mongoid::Document
end

describe "will paginate mongoid" do
  before(:all) do
    MongoidModel.delete_all
    4.times { MongoidModel.create! }
  end

  let(:criteria) { MongoidModel.criteria }

  describe "#page" do
    it "should forward to the paginate method" do
      criteria.expects(:paginate).with(:page => 2).returns("itself")
      criteria.page(2).should == "itself"
    end

    it "should not override per_page if set earlier in the chain" do
      criteria.paginate(:per_page => 10).page(1).per_page.should == 10
      criteria.paginate(:per_page => 20).page(1).per_page.should == 20
    end
  end

  describe "#paginate" do
    it "should use criteria" do
      criteria.paginate.should be_instance_of(::Mongoid::Criteria)
    end

    it "should not override page number if set earlier in the chain" do
      criteria.page(3).paginate.current_page.should == 3
    end

    it "should limit according to per_page parameter" do
      criteria.paginate(:per_page => 10).options.should include(:limit => 10)
    end

    it "should skip according to page and per_page parameters" do
      criteria.paginate(:page => 2, :per_page => 5).options.should include(:skip => 5)
    end

    specify "per_page should default to value configured for WillPaginate" do
      criteria.paginate.options.should include(:limit => WillPaginate.per_page)
    end

    specify "page should default to 1" do
      criteria.paginate.options.should include(:skip => 0)
    end

    it "should convert strings to integers" do
      criteria.paginate(:page => "2", :per_page => "3").options.should include(:limit => 3, :limit => 3)
    end

    describe "collection compatibility" do
      describe "#total_count" do
        it "should be calculated correctly" do
          criteria.paginate(:per_page => 1).total_entries.should == 4
          criteria.paginate(:per_page => 3).total_entries.should == 4
        end

        it "should be cached" do
          criteria.expects(:count).once.returns(123)
          criteria.paginate
          2.times { criteria.total_entries.should == 123 }
        end
      end

      it "should calculate total_pages" do
        criteria.paginate(:per_page => 1).total_pages.should == 4
        criteria.paginate(:per_page => 3).total_pages.should == 2
        criteria.paginate(:per_page => 10).total_pages.should == 1
      end

      it "should return per_page" do
        criteria.paginate(:per_page => 1).per_page.should == 1
        criteria.paginate(:per_page => 5).per_page.should == 5
      end

      describe "#current_page" do
        it "should return current_page" do
          criteria.paginate(:page => 1).current_page.should == WillPaginate::PageNumber(1)
          criteria.paginate(:page => 3).current_page.should == WillPaginate::PageNumber(3)
        end

        it "should be casted to PageNumber" do
          criteria.paginate(:page => 1).current_page.should be_instance_of(WillPaginate::PageNumber)
        end
      end

      it "should return offset" do
        criteria.paginate(:page => 1).offset.should == 0
        criteria.paginate(:page => 2, :per_page => 5).offset.should == 5
        criteria.paginate(:page => 3, :per_page => 10).offset.should == 20
      end

      it "should not pollute plain mongoid criterias" do
        %w(total_entries total_pages per_page current_page).each do |method|
          criteria.should_not respond_to(method)
        end
        criteria.offset.should be_nil # this is already a criteria method
      end
    end
  end
end
