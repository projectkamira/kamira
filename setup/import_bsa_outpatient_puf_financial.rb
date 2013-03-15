#!/usr/bin/env ruby

# The 2010_BSA_Outpatient_PUF.csv file has CPT or HCPCS codes and
# associated costs for ~1.4 million patient events; the fourth column
# contains the CPT code and the sixth column contains the cost. This
# script reads the file and, by looking up the codes in the value set,
# associates costs with OIDs and stores aggregate information on those
# costs in a collection

# FIXME: Need to document the process for downloading the appropriate files and running this script, plus need
# to decide if the OID_CPT_MAP approach (noted with VS_EXT) makes sense

# Run from the base kamira directory as
#
#  ruby setup/import_bsa_outpatient_puf_financial.rb CMS-DATA/2010_BSA_Outpatient_PUF.csv CMS-DATA/loinc/MRSMAP.RRF OID_CPT_MAP

require 'csv'
require 'descriptive_statistics'
require 'mongo'
include Mongo

db = Connection.new.db('kamira')
value_sets_collection = db.collection('health_data_standards_svs_value_sets')
costs_collection = db.collection('costs')

# Two arguments, first is the CMS file, second (optional) is the LOINC/CPT translation file
cms_file = ARGV[0]
loinc_cpt_file = ARGV[1]

# Create CPT -> LOINC lookup table
cpt_to_loinc = {}
if loinc_cpt_file
  CSV.foreach(loinc_cpt_file, col_sep: '|') do |row|
    loinc = row[4]
    cpt = row[8]
    cpt_to_loinc[cpt] = loinc
  end
end

# VS_EXT: Trying a third option, a hand-built OID to CPT code file (which essentially acts as an extension to the value sets)
oid_cpt_file = ARGV[2]
cpt_to_oid = {}
if oid_cpt_file
  CSV.foreach(oid_cpt_file) do |row|
    oid = row[0]
    row[1].split('|').each do |cpt_code|
      cpt_to_oid[cpt_code] = oid
    end
  end
end

# Load CMS data into a CPT code -> payments hash
code_payments = Hash.new { |h, k| h[k] = [] }

CSV.foreach(cms_file, headers: true) do |row|
  cpt_code = row[3]
  payment = row[5].to_f
  code_payments[cpt_code] << payment
end

puts "Parsed CMS records, detecting #{code_payments.size} distinct codes"

# We have a mapping from CPT/HCPCS code to payments; use value sets to create mapping from OIDs to payments
oid_payments = Hash.new { |h, k| h[k] = [] }
oid_names = Hash.new

# Look up each code in the value set and, if present, assign the costs to that OID
code_payments.each do |cpt_code, payments|
  value_sets_collection.find('concepts.code' => cpt_code, 'concepts.code_system_name' => { '$in' => ['CPT', 'HCPCS'] }).each do |vs|
    oid_payments[vs['oid']] += payments
    oid_names[vs['oid']] = vs['display_name']
  end
  # If we have a mapping to LOINC codes, try those as well
  if loinc_code = cpt_to_loinc[cpt_code]
    value_sets_collection.find('concepts.code' => loinc_code, 'concepts.code_system_name' => 'LOINC').each do |vs|
      oid_payments[vs['oid']] += payments
      oid_names[vs['oid']] = vs['display_name']
    end
  end
  # VS_EXT: Use our value set extending oid-to-cms mapping
  if oid = cpt_to_oid[cpt_code]
    oid_payments[oid] += payments
    oid_names[oid] = value_sets_collection.find_one(oid: oid)['display_name']
  end
end

puts "Collected codes and payments into #{oid_payments.size} OIDs"

# Given a set of values, calculate
def bounds(values)
  q1 = values.percentile(25)
  q3 = values.percentile(75)
  iqr = q3 - q1
  lower = q1 - (iqr * 1.5)
  upper = q3 + (iqr * 1.5)
  inrange = values.select { |v| v >= lower && v <= upper }
  lower = [lower, inrange.min].max
  upper = [upper, inrange.max].min
  belowrange = values.select { |v| v < lower }
  aboverange = values.select { |v| v > upper }
  
end

# Write aggregated data to the costs table
oid_payments.each do |oid, payments|
  costs_collection.remove(oid: oid)
  costs_collection.insert(oid: oid,
                          name: oid_names[oid],
                          count: payments.size,
                          min: payments.min,
                          firstQuartile: payments.percentile(25),
                          median: payments.median,
                          thirdQuartile: payments.percentile(75),
                          max: payments.max,
                          mean: payments.mean,
                          standardDev: payments.standard_deviation)
end
