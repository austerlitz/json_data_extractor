require 'spec_helper'

require "yaml"
require "json"
require "pry"
require "amazing_print"

require 'jsonpath'

RSpec.describe JsonDataExtractor do
  subject { described_class.new(json).extract(config) }

  let!(:json) do
    %q[{ "store": {
          "book": [ 
            { "category": "reference",
              "author": "Nigel Rees",
              "title": "Sayings of the Century",
              "price": 8.95
            },
            { "category": "fiction",
              "author": "Evelyn Waugh",
              "title": "Sword of Honour",
              "price": 12.99
            },
            { "category": "fiction",
              "author": "Herman Melville",
              "title": "Moby Dick",
              "isbn": "0-553-21311-3",
              "price": 8.99
            },
            { "category": "fiction",
              "author": "J. R. R. Tolkien",
              "title": "The Lord of the Rings",
              "isbn": "0-395-19395-8",
              "price": 22.99
            }
          ],
          "bicycle": {
            "color": "red",
            "price": 19.95
          }
        }
      }]
  end
  let!(:yml) do
    <<~YAML
      authors: 
        path: $.store.book[*].author
        modifier: downcase
      categories: $..category
    YAML
  end
  let!(:config) { YAML.safe_load(yml) }

  let!(:expected_result) do
    {
      "authors":    ["nigel rees", "evelyn waugh", "herman melville", "j. r. r. tolkien"],
      "categories": ["reference", "fiction", "fiction", "fiction"]
    }
  end

  it('does the thing') {
    puts JSON.pretty_generate(subject)
    expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result) }

  context 'some real-life example' do
    let(:json) {
      {
        "VEHICLES": [
                      {
                        "VENDORNAME":                   "Arya Rent a Car",
                        "VENDORLOGO":                   "https://cdn.kolaycar.com/vendor/1749.jpg",
                        "VENDORVEHICLENAME":            "",
                        "VEHICLEID":                    5,
                        "VEHICLENAME":                  "Hyundai i20",
                        "VEHICLEDESCRIPTION":           "",
                        "SIPPCODE":                     "EDMR",
                        "PICKUPLOCATIONID":             40,
                        "PICKUPLOCATIONNAME":           "Kayseri Airport",
                        "RETURNLOCATIONID":             40,
                        "RETURNLOCATIONNAME":           "Kayseri Airport",
                        "VENDORPICKUPLOCATIONID":       1,
                        "VENDORPICKUPLOCATIONNAME":     "Kayseri Erkilet Airport (ASR)",
                        "VENDORPICKUPLOCATIONGEO":      "",
                        "VENDORPICKUPLOCATIONTYPEID":   1,
                        "VENDORPICKUPLOCATIONTYPENAME": "Terminal Counter",
                        "VENDORRETURNLOCATIONID":       1,
                        "VENDORRETURNLOCATIONNAME":     "Kayseri Erkilet Airport (ASR)",
                        "VENDORRETURNLOCATIONGEO":      "",
                        "VENDORRETURNLOCATIONTYPEID":   1,
                        "VENDORRETURNLOCATIONTYPENAME": "Terminal Counter",
                        "VENDORMINDRIVERAGE":           21,
                        "VENDORMINDRIVINGLICENSEAGE":   2,
                        "PICKUPDATETIME":               "2022-08-15T10:00:00",
                        "RETURNDATETIME":               "2022-08-21T10:00:00",
                        "MINIMUMRENTALDURATIONDAYS":    1,
                        "RENTALDURATION":               6,
                        "DAILYPRICE":                   35.37,
                        "ONEWAYFEE":                    0.0,
                        "TOTALPRICE":                   212.22,
                        "DAILYPRICEPAYNOW":             35.37,
                        "TOTALPRICEPAYNOW":             212.22,
                        "DAILYPRICEBASE":               0.0,
                        "TOTALPRICEBASE":               310.68,
                        "DEPOSITPRICE":                 57.03,
                        "ISAVAILABLE":                  1,
                        "RENTALCONDITIONS":             [
                                                          {
                                                            "RENTALCONDITIONNAME":     "Fair Fuel Policy",
                                                            "RENTALCONDITIONNAMECODE": ""
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "Free Amendmend",
                                                            "RENTALCONDITIONNAMECODE": ""
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "Free Breakdown Assistance",
                                                            "RENTALCONDITIONNAMECODE": ""
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "Free Cancelation* (applied for pay later reservations)",
                                                            "RENTALCONDITIONNAMECODE": ""
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "HGS Higway and Bridges Payment Tool (only charges of usage may be collected as is)",
                                                            "RENTALCONDITIONNAMECODE": ""
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "Snow Tire (Seasonal Conditions)",
                                                            "RENTALCONDITIONNAMECODE": ""
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "VAT and all other TAXES",
                                                            "RENTALCONDITIONNAMECODE": ""
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "",
                                                            "RENTALCONDITIONNAMECODE": "on_airport"
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "",
                                                            "RENTALCONDITIONNAMECODE": "one_way_surcharge_included"
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "",
                                                            "RENTALCONDITIONNAMECODE": "supplier_known"
                                                          },
                                                          {
                                                            "RENTALCONDITIONNAME":     "",
                                                            "RENTALCONDITIONNAMECODE": "optimised_for_mobile"
                                                          }
                                                        ],
                        "VEHICLEIMAGES":                [
                                                          {
                                                            "VEHICLEIMAGE": "https://cdn.kolaycar.com/images/hyundai-i20.jpg"
                                                          }
                                                        ],
                        "VEHICLETYPE":                  "Hatchback 5 Doors",
                        "VEHICLETYPEID":                4,
                        "TRANSMISSIONTYPE":             "Manual",
                        "TRANSMISSIONTYPEID":           1,
                        "VEHICLECATEGORY":              "Economic",
                        "VEHICLECATEGORYID":            1,
                        "PASSENGERQUANTITY":            "5 Person",
                        "PASSENGERQUANTITYID":          3,
                        "FUELTYPE":                     "Gasoline",
                        "FUELTYPEID":                   1,
                        "BAGGAGEQUANTITY":              "3 Luggages",
                        "BAGGAGEQUANTITYID":            3,
                        "ISAIRCONDITION":               true,
                        "DELIVERYPAYMENTACTIVE":        true,
                        "CREDITCARDPAYMENTTYPE":        0,
                        "ADVANCEPAYMENTTYPE":           0,
                        "FREEDAILYPRICE":               false,
                        "FREEEXTRAPRICE":               false,
                        "FREEONEWAYFEE":                false,
                        "TOTALKMLIMIT":                 "1400",
                        "TOTALKMLIMITMAXPERRENTAL":     "1400"
                      }
                    ],
        "EXTRAS":   [
                      {
                        "EXTRAID":                  3,
                        "EXTRANAME":                "Additional Driver",
                        "EXTRADESCRIPTION":         "",
                        "EXTRATYPE":                "0",
                        "EXTRAPERDAY":              1,
                        "EXTRAQUANTITYINCREASABLE": "True",
                        "PRICE":                    1.71
                      },
                      {
                        "EXTRAID":                  2,
                        "EXTRANAME":                "Child Seat/Booster",
                        "EXTRADESCRIPTION":         "",
                        "EXTRATYPE":                "0",
                        "EXTRAPERDAY":              1,
                        "EXTRAQUANTITYINCREASABLE": "False",
                        "PRICE":                    2.85
                      },
                      {
                        "EXTRAID":                  1,
                        "EXTRANAME":                "GPS Navigation",
                        "EXTRADESCRIPTION":         "",
                        "EXTRATYPE":                "0",
                        "EXTRAPERDAY":              1,
                        "EXTRAQUANTITYINCREASABLE": "False",
                        "PRICE":                    2.57
                      },
                      {
                        "EXTRAID":                  8,
                        "EXTRANAME":                "Small Damage İnsurance",
                        "EXTRADESCRIPTION":         "You have the right to receive any damages to the vehicle up to 500 TL without a report.",
                        "EXTRATYPE":                "1",
                        "EXTRAPERDAY":              1,
                        "EXTRAQUANTITYINCREASABLE": "False",
                        "PRICE":                    2.85
                      },
                      {
                        "EXTRAID":                  9,
                        "EXTRANAME":                "Super Insurance",
                        "EXTRADESCRIPTION":         "It provides the right to meet the damages that may occur in the vehicle up to 2.000 TL without any report.",
                        "EXTRATYPE":                "1",
                        "EXTRAPERDAY":              1,
                        "EXTRAQUANTITYINCREASABLE": "False",
                        "PRICE":                    3.99
                      },
                      {
                        "EXTRAID":                  7,
                        "EXTRANAME":                "Tire - Glass - Headlamp Insurance",
                        "EXTRADESCRIPTION":         "",
                        "EXTRATYPE":                "1",
                        "EXTRAPERDAY":              1,
                        "EXTRAQUANTITYINCREASABLE": "False",
                        "PRICE":                    1.08
                      }
                    ]
      }.to_json
    }
    let!(:yml) do
      <<~YAML
        price: $..VEHICLES[0].DAILYPRICE
        rental_cost: $..VEHICLES[0].TOTALPRICE
        sipp: $..VEHICLES[0].SIPPCODE
        deposit: $..VEHICLES[0].DEPOSITPRICE
        rental_conditions: $..VEHICLES[0].RENTALCONDITIONS[*].RENTALCONDITIONNAME
      YAML
    end
    let!(:expected_result) do
      {
        price: 35.37,
        rental_cost: 212.22,
        sipp: 'EDMR',
        deposit: 57.03,
        rental_conditions: [
                             "Fair Fuel Policy",
                             "Free Amendmend",
                             "Free Breakdown Assistance",
                             "Free Cancelation* (applied for pay later reservations)",
                             "HGS Higway and Bridges Payment Tool (only charges of usage may be collected as is)",
                             "Snow Tire (Seasonal Conditions)",
                             "VAT and all other TAXES",
                             "",
                             "",
                             "",
                             ""
                           ],
      }
    end
    it 'woa' do
      puts JSON.pretty_generate(subject)
      expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result)
    end
  end

  it "has a version number" do
    expect(JsonDataExtractor::VERSION).not_to be nil
  end

end
