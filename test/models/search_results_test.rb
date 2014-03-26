require 'test_helper'

describe "Aspect" do
  PAC = "ppd:propertyAddressCounty"
  PAL = "ppd:propertyAddressLocality"
  PAD = "ppd:propertyAddressDistrict"
  PAT = "ppd:propertyAddressTown"
  PAS = "ppd:propertyAddressStreet"
  PAP = "ppd:propertyAddressPaon"
  PASN = "ppd:propertyAddressSaon"

  it "should index a sample result" do
    result = {PAC => {"@value" => "a-county"},
              PAL => {"@value" => "a-locality"},
              PAD => {"@value" => "a-district"},
              PAT => {"@value" => "a-town"},
              PAS => {"@value" => "a-street"},
              PAP => {"@value" => "a-paon"},
              PASN => {"@value" => "a-saon"},
              "ppd:pricePaid" => 100
             }

    sr = SearchResults.new( [result] )

    sr.index.must_be_kind_of Hash
    sr.index["a-county"].must_be_kind_of Hash
    sr.index["a-county"]["a-locality"].must_be_kind_of Hash
    sr.index["a-county"]["a-locality"]["a-district"].must_be_kind_of Hash
    sr.index["a-county"]["a-locality"]["a-district"]["a-town"].must_be_kind_of Hash
    sr.index["a-county"]["a-locality"]["a-district"]["a-town"]["a-street"].must_be_kind_of Hash
    sr.index["a-county"]["a-locality"]["a-district"]["a-town"]["a-street"]["a-paon"].must_be_kind_of Hash
    sr.index["a-county"]["a-locality"]["a-district"]["a-town"]["a-street"]["a-paon"]["a-saon"].must_be_kind_of Array
    sr.index["a-county"]["a-locality"]["a-district"]["a-town"]["a-street"]["a-paon"]["a-saon"][0]["ppd:pricePaid"].must_equal 100
  end

  it "should index in the face of missing values" do
    result = {PAC => {"@value" => "a-county"},
              PAD => {"@value" => "a-district"},
              PAT => {"@value" => "a-town"},
              PAS => {"@value" => "a-street"},
              PAP => {"@value" => "a-paon"},
              PASN => {"@value" => ""},
              "ppd:pricePaid" => 100
             }

    sr = SearchResults.new( [result] )

    sr.index.must_be_kind_of Hash
    sr.index["a-county"].must_be_kind_of Hash
    sr.index["a-county"][:no_value].must_be_kind_of Hash
    sr.index["a-county"][:no_value]["a-district"].must_be_kind_of Hash
    sr.index["a-county"][:no_value]["a-district"]["a-town"].must_be_kind_of Hash
    sr.index["a-county"][:no_value]["a-district"]["a-town"]["a-street"].must_be_kind_of Hash
    sr.index["a-county"][:no_value]["a-district"]["a-town"]["a-street"]["a-paon"].must_be_kind_of Hash
    sr.index["a-county"][:no_value]["a-district"]["a-town"]["a-street"]["a-paon"][:no_value].must_be_kind_of Array
    sr.index["a-county"][:no_value]["a-district"]["a-town"]["a-street"]["a-paon"][:no_value][0]["ppd:pricePaid"].must_equal 100
  end

  it "should traverse in order" do
    result0 = {PAC => {"@value" => "a-county"},
               PAL => {"@value" => "a-locality"},
               PAD => {"@value" => "a-district"},
               PAT => {"@value" => "a-town"},
               PAS => {"@value" => "c-street"},
               PAP => {"@value" => "a-paon"},
               PASN => {"@value" => "a-saon"},
               "ppd:pricePaid" => 100,
               "ppd:transactionDate" => {"@value" => "2013-01-01"}
              }
    result1 = {PAC => {"@value" => "a-county"},
               PAL => {"@value" => "a-locality"},
               PAD => {"@value" => "a-district"},
               PAT => {"@value" => "a-town"},
               PAS => {"@value" => "d-street"},
               PAP => {"@value" => "a-paon"},
               PASN => {"@value" => "a-saon"},
               "ppd:pricePaid" => 101,
               "ppd:transactionDate" => {"@value" => "2013-01-01"}
              }
    result2 = {PAC => {"@value" => "a-county"},
               PAL => {"@value" => "a-locality"},
               PAD => {"@value" => "a-district"},
               PAT => {"@value" => "b-town"},
               PAS => {"@value" => "d-street"},
               PAP => {"@value" => "a-paon"},
               PASN => {"@value" => "a-saon"},
               "ppd:pricePaid" => 102,
               "ppd:transactionDate" => {"@value" => "2013-01-01"}
              }
    result3 = {PAC => {"@value" => "a-county"},
               PAL => {"@value" => "a-locality"},
               PAD => {"@value" => "a-district"},
               PAT => {"@value" => "b-town"},
               PAS => {"@value" => "e-street"},
               PAP => {"@value" => "a-paon"},
               PASN => {"@value" => "a-saon"},
               "ppd:pricePaid" => 110,
               "ppd:transactionDate" => {"@value" => "2014-01-01"}
              }
    result4 = {PAC => {"@value" => "a-county"},
               PAL => {"@value" => "a-locality"},
               PAD => {"@value" => "a-district"},
               PAT => {"@value" => "b-town"},
               PAS => {"@value" => "e-street"},
               PAP => {"@value" => "a-paon"},
               PASN => {"@value" => "a-saon"},
               "ppd:pricePaid" => 109,
               "ppd:transactionDate" => {"@value" => "2014-01-02"}
              }
    result5 = {PAC => {"@value" => "a-county"},
               PAL => {"@value" => "a-locality"},
               PAD => {"@value" => "a-district"},
               PAT => {"@value" => "b-town"},
               PAS => {"@value" => "e-street"},
               PAP => {"@value" => "a-paon"},
               PASN => {"@value" => "a-saon"},
               "ppd:pricePaid" => 108,
               "ppd:transactionDate" => {"@value" => "2014-01-03"}
              }

    sr = SearchResults.new( [result0,result1,result2,result3,result4,result5] )

    prices = []
    sr.traverse {|tx| prices << tx["ppd:pricePaid"]}
    prices.must_equal [100,101,102,108,109,110]
  end
end
