require 'digest/sha1'
require "uri"

require "not_relational/domain_model.rb"
module Rengine

  class Weblab < NotRelational::DomainModel
    property :id,:string,:is_primary_key=>true
    property :name,:string
    property :is_active ,:boolean                             
    property :is_test ,:boolean                             
    property :adsense_channel,:string
    property :score,:integer
    property :layout,:text
    property :stylesheet,:text
    property :created_date,:date

  end
end
