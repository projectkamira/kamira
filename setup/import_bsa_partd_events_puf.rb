#!/usr/bin/env ruby

# The 2008_BSA_PartD_Events_PUF_1.csv file has data that we can associate with the appropriate RxNorm code to
# create cost information for prescription events

# FIXME: Need to document the process for downloading the appropriate files and running this script

# Change directory to CMS-DATA/prescription_drug and run as
#
#   ruby ../../setup/import_bsa_partd_events_puf.rb 2008_BSA_PartD_Events_PUF_1.csv

require 'csv'
require 'descriptive_statistics'
require 'mongo'
include Mongo

def load_lookup(filename)
  CSV.read(filename).each_with_object({}) { |row, hash| hash[row[0]] = row[1] }
end

puts "Loading lookup tables"

drug_name = load_lookup('./DRUG_NAME_TABLE.csv')
drug_strength = load_lookup('./DRUG_STRENGTH_TABLE.csv')
drug_strength_unit = load_lookup('./DRUG_STRENGTH_UNITS_TABLE.csv')
drug_doseform = load_lookup('./DRUG_DOSEFORM_TABLE.csv')

db = Connection.new.db('kamira')
value_sets_collection = db.collection('health_data_standards_svs_value_sets')
costs_collection = db.collection('costs')

drug_costs = Hash.new { |h, k| h[k] = [] }
display_name_regexp = Hash.new

puts "Reading CMS data file"
CSV.foreach(ARGV[0], headers: true) do |row|
  next unless name = drug_name[row[3]]
  next unless strength = drug_strength[row[4]]
  next unless strength_unit = drug_strength_unit[row[5]]
  next unless doseform = drug_doseform[row[6]]
  display_name = "#{name} #{strength} #{strength_unit} #{doseform}"
  drug_costs[display_name] << row[10].to_i
  # Sometimes the CMS data leaves out part of the drug name, ie Tramadol Hydrochloride is listed as simply Tramadol;
  # to compensate we search using a regexp in addition to the name
  display_name_regexp[display_name] = (/^#{name} \S+ #{strength} #{strength_unit} #{doseform}$/i rescue nil)
end

oid_costs = Hash.new { |h, k| h[k] = [] }
oid_names = Hash.new

puts "Looking up OIDs for #{drug_costs.size} distinct medications"
drug_costs.each do |display_name, costs|
  value_sets_collection.find('$or' => [{ 'concepts.display_name' => display_name },
                                       { 'concepts.display_name' => display_name_regexp[display_name] }]).each do |vs|
    oid_costs[vs['oid']] += costs
    oid_names[vs['oid']] = vs['display_name']
  end
end

puts "Writing cost information into database for #{oid_costs.size} OIDs"
oid_costs.each do |oid, costs|
  costs_collection.remove(oid: oid)  
  costs_collection.insert(oid: oid,
                          name: oid_names[oid],
                          count: costs.size,
                          min: costs.min,
                          firstQuartile: costs.percentile(25),
                          median: costs.median,
                          thirdQuartile: costs.percentile(75),
                          max: costs.max,
                          mean: costs.mean,
                          standardDev: costs.standard_deviation)
end

puts "Done!"
