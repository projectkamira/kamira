# Quick code to read the CHPL Excel spreadsheet and count the number of implementatios of the various measures

require 'spreadsheet'

exit unless ARGV.size > 0

book = Spreadsheet.open ARGV.first
sheet = book.worksheet 0

header = sheet.row(0)

# Use a structure based on the headers from all the columns
Product = Struct.new(*header.map(&:to_sym))
products = []

# Argument to each means skip that many rows
sheet.each 1 do |row|
  products << Product.new(*row)
end

# Count number of implementations for each measure, of the ones we care about
measure_names = header.select { |h| h.match /^NQF/ }

measure_count = Hash.new(0)

products.each do |product|
  measure_names.each do |measure_name|
    measure_count[measure_name] += product[measure_name].to_i
  end
end

# List by most implementations to fewest
measure_count.sort_by { |k, v| v }.reverse.each do |measure, count|
  puts "%4d  %s" % [count, measure]
end
