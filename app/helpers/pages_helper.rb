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

  def points_over_time
        all_dates = @cumulative_points_by_participant_day.values
                                                    .flat_map(&:keys)
                                                    .uniq
                                                    .map { |d_str| Date.parse(d_str) rescue d_str } # Parse if possible, keep string otherwise
                                                    .sort

    # Store formatted labels for the chart's X-axis
    @chart_labels = all_dates.map { |date| date.strftime("%d %b") } # e.g., "24 Apr"

    # 2. Create the final data structure for the chart, filling gaps
    @chart_cumulative_data = Hash.new { |h, k| h[k] = {} }
    last_known_points = Hash.new(0) # Keep track of the last score for each participant

    # Assuming you have @participants = current_user.participants.where(archived: false).order(:name)
    @participants.each do |participant|
      last_known_points[participant.name] = 0 # Reset for each participant
      participant_data = @cumulative_points_by_participant_day[participant.name] || {}

      all_dates.each do |date|
        date_key = date.is_a?(Date) ? date.to_s : date # Use string key matching original data

        # If there's an entry for this specific date, update the last known points
        if participant_data.key?(date_key)
          last_known_points[participant.name] = participant_data[date_key]
        end

        # Store the current cumulative value (either updated or carried over)
        # Use the formatted date string as the key for easy lookup in the view later
        formatted_date = date.strftime("%d %b")
        @chart_cumulative_data[participant.name][formatted_date] = last_known_points[participant.name]

        @chart_cumulative_data
      end
    end
  end
end
