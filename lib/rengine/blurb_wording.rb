require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
require File.dirname(__FILE__) +"/blurb.rb"
module Rengine
  class BlurbWording < NotRelational::DomainModel
    property :id,:string,:is_primary_key=>true
    property :blurb_id,:string
    property :text,:text
    property :title , :string  
    property :version , :string  
    property :author , :string  
    property :language_id , :string  
    property :time_utc , :date
    
    belongs_to :Blurb
    
    index :blurb_and_language,[:blurb_id,:language_id],:unique=>true
  end
end
