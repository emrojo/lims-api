require 'spec_helper'

require 'lims-api/context_service'
require 'lims-core'
require 'lims-core/persistence/sequel'

require 'integrations/lab_resource_shared'
require 'lims-api/resource_shared'
require 'integrations/spec_helper'

def create_well_hash
  {}.tap do |h| 
    (1..number_of_rows).each do |r|
      (1..number_of_columns).each do |c|
        h["#{(?A.ord+r-1).chr}#{c}"]=[]
      end
    end
  end
end

shared_context "expect empty plate" do
  # We don't use here Plate methods to generate the wells hash
  # because 
  let(:well_hash) { create_well_hash }
end

shared_context "expect plate JSON" do
  let (:expected_json) {
    path = "http://example.org/#{uuid}"
    { "plate" => {"actions" => {"read" => path,
        "update" => path,
        "delete" => path,
        "create" => path},
      "uuid" => uuid,
      "dimension" => {
        "number_of_rows" => number_of_rows,
        "number_of_columns" => number_of_columns
      },
      "wells" => well_hash}
    }
  }
end

shared_context "for empty plate" do
  let (:parameters) { dimension }
  include_context "expect empty plate"
end

shared_context "for plate with samples" do
  let (:parameters) {  dimension.merge(:wells_description => wells_description) }
  include_context "with saved sample"
  include_context "with filled aliquots"
  let(:wells_description) { { "C5" => [{"sample_uuid" => sample_uuid }] } }
  let(:wells_description_response) { { "C5" => aliquot_array } }
  let(:well_hash) { create_well_hash.merge(wells_description_response) }
end

shared_examples_for "with saved plate with samples" do
  include_context "has standard dimension"
  subject { described_class.new(:number_of_rows => number_of_rows,
                                :number_of_columns => number_of_columns) }
  let (:sample_location) { :C5 }
  include_context "with sample in location"
end

describe Lims::Core::Laboratory::Plate do
  include_context "use core context service", :plates, :samples
  include_context "JSON"
  let(:model) { "plates" }

  context "#create" do
    include_context "has standard dimension"
    context "with empty plates" do
      include_context "for empty plate"
      include_context "expect plate JSON"
      it_behaves_like('creating a resource')
    end
    context "with plates with samples" do
      include_context "for plate with samples"
      include_context "expect plate JSON"
      it_behaves_like('creating a resource')
    end
  end

  context "#page" do
    context "with 1 plate" do
      include_context "with saved plate with samples"
      let (:viewed_aliquot_array) {
        path = "http://example.org/#{sample_uuid}"
        [ { "sample"=> {"actions" => { "read" => path,
          "update" => path,
          "delete" => path,
          "create" => path }}} ]
      }

      it "display a page" do
        path = "http://example.org/#{uuid}"
        get("plates/page=1").body.should match_json({
              "actions"=>{
                "read"=>"http://example.org/plates/page=1",
                "first"=>"http://example.org/plates/page=1",
                "last"=>"http://example.org/plates/page=-1"},
              "plates"=>[
                {"plate" =>
                  {"actions"=>{"read"=> path,
                    "update"=> path,
                    "delete"=> path,
                    "create"=> path,
                   },
         "uuid" => uuid,
         "dimension" => {
            "number_of_rows" => number_of_rows,
            "number_of_columns" => number_of_columns
          },
        "wells"=>{
          "A1"=>[],"A2"=>[],"A3"=>[],"A4"=>[],"A5"=>[],"A6"=>[],"A7"=>[],"A8"=>[],"A9"=>[],"A10"=>[],"A11"=>[],"A12"=>[],
          "B1"=>[],"B2"=>[],"B3"=>[],"B4"=>[],"B5"=>[],"B6"=>[],"B7"=>[],"B8"=>[],"B9"=>[],"B10"=>[],"B11"=>[],"B12"=>[],
          "C1"=>[],"C2"=>[],"C3"=>[],"C4"=>[],"C5"=>viewed_aliquot_array,"C6"=>[],"C7"=>[],"C8"=>[],"C9"=>[],"C10"=>[],"C11"=>[],"C12"=>[],
          "D1"=>[],"D2"=>[],"D3"=>[],"D4"=>[],"D5"=>[],"D6"=>[],"D7"=>[],"D8"=>[],"D9"=>[],"D10"=>[],"D11"=>[],"D12"=>[],
          "E1"=>[],"E2"=>[],"E3"=>[],"E4"=>[],"E5"=>[],"E6"=>[],"E7"=>[],"E8"=>[],"E9"=>[],"E10"=>[],"E11"=>[],"E12"=>[],
          "F1"=>[],"F2"=>[],"F3"=>[],"F4"=>[],"F5"=>[],"F6"=>[],"F7"=>[],"F8"=>[],"F9"=>[],"F10"=>[],"F11"=>[],"F12"=>[],
          "G1"=>[],"G2"=>[],"G3"=>[],"G4"=>[],"G5"=>[],"G6"=>[],"G7"=>[],"G8"=>[],"G9"=>[],"G10"=>[],"G11"=>[],"G12"=>[],
          "H1"=>[],"H2"=>[],"H3"=>[],"H4"=>[],"H5"=>[],"H6"=>[],"H7"=>[],"H8"=>[],"H9"=>[],"H10"=>[],"H11"=>[],"H12"=>[]}}}],
        "size"=>1
        })
      end
    end
    context do
      it "display an empty page" do
        #create a plate
        get("plates/page=1").body.should match_json({
          "actions"=>{
            "read"=>"http://example.org/plates/page=1",
            "first"=>"http://example.org/plates/page=1",
            "last"=>"http://example.org/plates/page=-1"},
          "plates"=>[],
          "size"=>0
        })
      end
    end
  end
  context "#transfer" do
    let(:url) { "/actions/plate_transfer" }
    context "with empty parameters",:focus  => 1  do
      let(:parameters) { {} }
      let(:expected_json)  { {"errors" => {:source => "invalid",
      :target => "invalid",
      :transfer_map => "invalid" }
      }}
      it_behaves_like "an invalid core action", 422  # Unprocessable entity
    end

    context "from a plate with sample" do
      include_context "with filled aliquots"
      let(:transfer_map)  {{ "C5" => "B2" }}
      context "to an existing target", :focus  => true do
        let(:target_uuid) {     '11111111-2222-3333-1111-000000000000'.tap do |uuid|
          store.with_session do |session|
            plate = Lims::Core::Laboratory::Plate.new(:number_of_rows => 8, :number_of_columns => 12)
            session << plate
            set_uuid(session, plate, uuid)
          end
        end}
        let(:parameters) { {:source_uuid => uuid, :target_uuid => target_uuid, :transfer_map => transfer_map  } }
        let(:source_wells) {{
          "A1"=>[],"A2"=>[],"A3"=>[],"A4"=>[],"A5"=>[],"A6"=>[],"A7"=>[],"A8"=>[],"A9"=>[],"A10"=>[],"A11"=>[],"A12"=>[],
          "B1"=>[],"B2"=>[],"B3"=>[],"B4"=>[],"B5"=>[],"B6"=>[],"B7"=>[],"B8"=>[],"B9"=>[],"B10"=>[],"B11"=>[],"B12"=>[],
          "C1"=>[],"C2"=>[],"C3"=>[],"C4"=>[],"C5"=>aliquot_array,"C6"=>[],"C7"=>[],"C8"=>[],"C9"=>[],"C10"=>[],"C11"=>[],"C12"=>[],
          "D1"=>[],"D2"=>[],"D3"=>[],"D4"=>[],"D5"=>[],"D6"=>[],"D7"=>[],"D8"=>[],"D9"=>[],"D10"=>[],"D11"=>[],"D12"=>[],
          "E1"=>[],"E2"=>[],"E3"=>[],"E4"=>[],"E5"=>[],"E6"=>[],"E7"=>[],"E8"=>[],"E9"=>[],"E10"=>[],"E11"=>[],"E12"=>[],
          "F1"=>[],"F2"=>[],"F3"=>[],"F4"=>[],"F5"=>[],"F6"=>[],"F7"=>[],"F8"=>[],"F9"=>[],"F10"=>[],"F11"=>[],"F12"=>[],
          "G1"=>[],"G2"=>[],"G3"=>[],"G4"=>[],"G5"=>[],"G6"=>[],"G7"=>[],"G8"=>[],"G9"=>[],"G10"=>[],"G11"=>[],"G12"=>[],
          "H1"=>[],"H2"=>[],"H3"=>[],"H4"=>[],"H5"=>[],"H6"=>[],"H7"=>[],"H8"=>[],"H9"=>[],"H10"=>[],"H11"=>[],"H12"=>[]}}
          let(:target_wells) { {
            "A1"=>[],"A2"=>[],"A3"=>[],"A4"=>[],"A5"=>[],"A6"=>[],"A7"=>[],"A8"=>[],"A9"=>[],"A10"=>[],"A11"=>[],"A12"=>[],
            "B1"=>[],"B2"=>aliquot_array,"B3"=>[],"B4"=>[],"B5"=>[],"B6"=>[],"B7"=>[],"B8"=>[],"B9"=>[],"B10"=>[],"B11"=>[],"B12"=>[],
            "C1"=>[],"C2"=>[],"C3"=>[],"C4"=>[],"C5"=>[],"C6"=>[],"C7"=>[],"C8"=>[],"C9"=>[],"C10"=>[],"C11"=>[],"C12"=>[],
            "D1"=>[],"D2"=>[],"D3"=>[],"D4"=>[],"D5"=>[],"D6"=>[],"D7"=>[],"D8"=>[],"D9"=>[],"D10"=>[],"D11"=>[],"D12"=>[],
            "E1"=>[],"E2"=>[],"E3"=>[],"E4"=>[],"E5"=>[],"E6"=>[],"E7"=>[],"E8"=>[],"E9"=>[],"E10"=>[],"E11"=>[],"E12"=>[],
            "F1"=>[],"F2"=>[],"F3"=>[],"F4"=>[],"F5"=>[],"F6"=>[],"F7"=>[],"F8"=>[],"F9"=>[],"F10"=>[],"F11"=>[],"F12"=>[],
            "G1"=>[],"G2"=>[],"G3"=>[],"G4"=>[],"G5"=>[],"G6"=>[],"G7"=>[],"G8"=>[],"G9"=>[],"G10"=>[],"G11"=>[],"G12"=>[],
            "H1"=>[],"H2"=>[],"H3"=>[],"H4"=>[],"H5"=>[],"H6"=>[],"H7"=>[],"H8"=>[],"H9"=>[],"H10"=>[],"H11"=>[],"H12"=>[]}}
            let(:expected_json) {
              source_url = "http://example.org/#{uuid}"
              target_url = "http://example.org/#{target_uuid}"
              {:plate_transfer =>
                {:actions => {},
                  :user => "user",
                  :application => "application",
                  :source => {"plate" => {"actions" => {"read" => source_url,
                    "update" => source_url,
                    "delete" => source_url,
                    "create" => source_url} ,
                    "uuid" => uuid,
                    "dimension" => {
                       "number_of_rows" => number_of_rows,
                       "number_of_columns" => number_of_columns
                     },
                    "wells"=> source_wells}},
                  :target => { "plate" => { "actions" => {"read" => target_url,
                    "update" => target_url,
                    "delete" => target_url,
                    "create" => target_url} ,
                    "uuid" => target_uuid,
                    "dimension" => {
                       "number_of_rows" => number_of_rows,
                       "number_of_columns" => number_of_columns
                     },
                    "wells"=> target_wells}},
                    :transfer_map => { "C5" => "B2" }
                }
              }
            }
                include_context "with saved plate with samples"
                it_behaves_like "a valid core action" do
                end
      end
    end

  end
end
