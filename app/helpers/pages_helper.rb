module PagesHelper
def format_data_for_chart(data)
  formatted_data = Hash.new { |hash, key| hash[key] = {} }

  data.each do |(name, date), count|
    formatted_data[name][date] = count
  end

  formatted_data.transform_values do |date_counts|
    date_counts.sort.to_h
  end
end 
end
