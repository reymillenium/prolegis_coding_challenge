require 'csv'
require 'json'
require 'open-uri'

CSV_PATH = "./activities.csv"
JSON_PATH = "./output.json"

# Boilerplate: This reads the csv and parses it
def csv
  @csv_table ||= begin
                   csv_raw = File.read(CSV_PATH)
                   CSV.parse(csv_raw, headers: true)
                 end

end

# Boilerplate: This writes the output of the script as JSON to a file.
def write_json(output)
  File.write(JSON_PATH, output.to_json)
end

# Implementation goes here

def clean_bill_id(bill_id_raw)
  # bill_id_raw.gsub(".", "").gsub(" ", "").downcase
  bill_id_raw.gsub(Regexp.union('.', ' '), '').downcase
end

def transform(row)
  table_index = row[0].to_i
  description = row[1]
  year = row[2].to_i
  congress_number = ((year - 1789) / 2) + 1

  # Gathering of the urls from the description:
  bill_reg_expr = /H.?R.?[ ]?\d+/
  bill_ids_raw = description.scan(bill_reg_expr)
  bill_ids_refined = bill_ids_raw.map { |bill_id_raw| clean_bill_id(bill_id_raw) }
  final_bill_ids = bill_ids_refined.map { |bill_id_refined| "#{bill_id_refined}-#{congress_number}" }
  urls = final_bill_ids.map { |final_bill_id| "https://www.prolegis.com/cards/v1/bills/#{final_bill_id}" }
  {
    id: table_index,
    urls: urls,
  }
end

# We generate a CSV Table object (@csv_table):
csv()

# Generates the data but with urls still not merged (based on the same id in the CSV Table object)
raw_data = @csv_table.map { |row| transform(row) }

# Merges the urls, keeping unique the entries:
merged_data = []
raw_data.each do |item|
  newItem = { id: item[:id], urls: [] }
  raw_data.each do |innerItem|
    if innerItem[:id] == item[:id]
      newItem[:urls] = newItem[:urls].concat(innerItem[:urls])
    end
  end
  merged_data.push(newItem) unless merged_data.include?(newItem)
end

# Writes the result in a json file:
write_json(merged_data)