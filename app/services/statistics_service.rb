class StatisticsService
  def initialize(user_or_household, participants = nil, interval = nil, start_date = nil, end_date = nil)
    if user_or_household.is_a?(User)
      @user = user_or_household
      @household = user_or_household.current_household
      raise ArgumentError, "User must have a current household" if @household.nil?
    else
      @household = user_or_household
      @user = nil
    end
    @participants = participants || @household.participants.includes(actions: :task)
    @interval = interval
    @start_date = start_date
    @end_date = end_date
    @date_range = calculate_date_range(interval, start_date, end_date)
  end

  def generate_task_completion_data
    query = ActionParticipant
      .joins(:participant, action: :task)
      .where(participants: { household_id: household.id })
      .group("tasks.title", "participants.name")
      .select(
        "tasks.title AS task_title",
        "participants.name AS participant_name",
        "COUNT(action_participants.id) AS actions_count",
        "tasks.worth AS task_worth"
      )
      .where("tasks.archived = ?", false)
      .order("tasks.title", "participants.name")
    
    apply_date_filter(query)
  end

  def generate_task_completion_by_participant
    query = ActionParticipant
      .joins(:participant)
      .where(participants: { household_id: household.id })
      .group("participants.name")
    
    apply_date_filter(query).count
  end

  def generate_task_completion_by_action(data)
    task_completion_by_action = Hash.new { |h, k| h[k] = {} }
    data.each do |item|
      task_title = item[:task_title]
      participant_name = item[:participant_name]
      points = item[:actions_count] * item[:task_worth]
      task_completion_by_action[task_title][participant_name] = points
    end
    task_completion_by_action
  end

  def generate_points_by_participant
    query = ActionParticipant
      .joins(:participant, action: :task)
      .where(participants: { household_id: household.id })
      .group("participants.name")
    
    apply_date_filter(query).sum("action_participants.points_earned")
  end

  def generate_task_popularity
    # Get task completion counts with position for sorting
    task_data = ActionParticipant
      .joins(:participant, action: :task)
      .where(participants: { household_id: household.id })
      .then { |query| apply_date_filter(query) }
      .group("tasks.title", "tasks.position")
      .count
    
    # Group by title and sum counts, keeping track of position
    result = {}
    task_data.each do |(title, position), count|
      if result[title]
        result[title][:count] += count
      else
        result[title] = { count: count, position: position }
      end
    end
    
    # Sort by position and return hash with title => count
    result
      .sort_by { |_, data| data[:position] || Float::INFINITY }
      .map { |title, data| [title, data[:count]] }
      .to_h
  end

  def generate_activity_over_time
    query = ActionParticipant
      .joins(:participant)
      .where(participants: { household_id: household.id })
    
    if date_range
      query.where(created_at: date_range).group_by_day(:created_at).count
    else
      query.group_by_day(:created_at, last: 30).count
    end
  end

  def generate_participant_activity
    query = ActionParticipant
      .joins(:participant)
      .where(participants: { household_id: household.id })
      .group("participants.name")
    
    if date_range
      query.where(created_at: date_range).group_by_day(:created_at).count
    else
      query.group_by_day(:created_at, last: 30).count
    end
  end

  def generate_points_by_day
    query = ActionParticipant
      .joins(:participant, action: :task)
      .where(participants: { household_id: household.id })
    
    if date_range
      query.where(created_at: date_range).group_by_day(:created_at).sum("action_participants.points_earned")
    else
      query.group_by_day(:created_at, last: 30).sum("action_participants.points_earned")
    end
  end

  def generate_bonus_points_by_day
    query = ActionParticipant
      .joins(:participant)
      .where(participants: { household_id: household.id })
      .where.not(bonus_points: nil)
    
    if date_range
      query.where(created_at: date_range).group_by_day(:created_at).sum("action_participants.bonus_points")
    else
      query.group_by_day(:created_at, last: 30).sum("action_participants.bonus_points")
    end
  end

  def generate_cumulative_bonus_data
    if date_range
      # For interval views: get cumulative bonus data within the interval but with true cumulative values
      generate_interval_cumulative_bonus_data
    else
      # For "all time" view: get all cumulative bonus data
      generate_all_time_cumulative_bonus_data
    end
  end

  def generate_all_time_cumulative_bonus_data
    # SQL query for cumulative bonus points calculation
    select_cumulative_sql = <<-SQL.squish
      DISTINCT
      participants.name AS participant_name,
      DATE(action_participants.created_at) AS action_date,
      SUM(COALESCE(action_participants.bonus_points, 0)) OVER (
        PARTITION BY participants.name
        ORDER BY DATE(action_participants.created_at)
        ROWS UNBOUNDED PRECEDING
      ) AS cumulative_bonus_points
    SQL

    query = ActionParticipant
      .joins(:participant)
      .where(participants: { household_id: household.id })
      .select(select_cumulative_sql)
      .where.not(bonus_points: nil)
      .order("participant_name", "action_date")

    # Process into nested hash
    cumulative_bonus_by_participant_day = Hash.new { |h, k| h[k] = {} }
    query.each do |record|
      date_key = record.action_date
      cumulative_bonus_by_participant_day[record.participant_name][date_key] = record.cumulative_bonus_points
    end

    cumulative_bonus_by_participant_day
  end

  def generate_interval_cumulative_bonus_data
    # Get all bonus data (not filtered by date) but only return dates within the interval
    select_cumulative_sql = <<-SQL.squish
      DISTINCT
      participants.name AS participant_name,
      DATE(action_participants.created_at) AS action_date,
      SUM(COALESCE(action_participants.bonus_points, 0)) OVER (
        PARTITION BY participants.name
        ORDER BY DATE(action_participants.created_at)
        ROWS UNBOUNDED PRECEDING
      ) AS cumulative_bonus_points
    SQL

    all_data = ActionParticipant
      .joins(:participant)
      .where(participants: { household_id: household.id })
      .select(select_cumulative_sql)
      .where.not(bonus_points: nil)
      .order("participant_name", "action_date")

    # Filter to only include dates within the interval for display
    cumulative_bonus_by_participant_day = Hash.new { |h, k| h[k] = {} }
    all_data.each do |record|
      action_date = Date.parse(record.action_date.to_s)
      if action_date >= date_range.begin.to_date && action_date <= date_range.end.to_date
        date_key = record.action_date
        cumulative_bonus_by_participant_day[record.participant_name][date_key] = record.cumulative_bonus_points
      end
    end

    cumulative_bonus_by_participant_day
  end

  def generate_cumulative_data
    if date_range
      # For interval views: get cumulative data within the interval but calculate true cumulative values
      generate_interval_cumulative_data
    else
      # For "all time" view: get all cumulative data
      generate_all_time_cumulative_data
    end
  end

  def generate_all_time_cumulative_data
    # SQL query for cumulative points calculation
    select_cumulative_sql = <<-SQL.squish
      DISTINCT
      participants.name AS participant_name,
      DATE(action_participants.created_at) AS action_date,
      SUM(action_participants.points_earned) OVER (
        PARTITION BY participants.name
        ORDER BY DATE(action_participants.created_at)
        ROWS UNBOUNDED PRECEDING
      ) AS cumulative_points
    SQL

    query = ActionParticipant
      .joins(:participant, action: :task)
      .where(participants: { household_id: household.id })
      .select(select_cumulative_sql)
      .where("action_participants.points_earned > 0")
      .order("participant_name", "action_date")

    # Process into nested hash
    cumulative_points_by_participant_day = Hash.new { |h, k| h[k] = {} }
    query.each do |record|
      date_key = record.action_date
      cumulative_points_by_participant_day[record.participant_name][date_key] = record.cumulative_points
    end

    cumulative_points_by_participant_day
  end

  def generate_interval_cumulative_data
    # Get all data (not filtered by date) but only return dates within the interval
    select_cumulative_sql = <<-SQL.squish
      DISTINCT
      participants.name AS participant_name,
      DATE(action_participants.created_at) AS action_date,
      SUM(action_participants.points_earned) OVER (
        PARTITION BY participants.name
        ORDER BY DATE(action_participants.created_at)
        ROWS UNBOUNDED PRECEDING
      ) AS cumulative_points
    SQL

    all_data = ActionParticipant
      .joins(:participant, action: :task)
      .where(participants: { household_id: household.id })
      .select(select_cumulative_sql)
      .where("action_participants.points_earned > 0")
      .order("participant_name", "action_date")

    # Filter to only include dates within the interval for display
    cumulative_points_by_participant_day = Hash.new { |h, k| h[k] = {} }
    all_data.each do |record|
      action_date = Date.parse(record.action_date.to_s)
      if action_date >= date_range.begin.to_date && action_date <= date_range.end.to_date
        date_key = record.action_date
        cumulative_points_by_participant_day[record.participant_name][date_key] = record.cumulative_points
      end
    end

    cumulative_points_by_participant_day
  end

  def generate_chart_cumulative_data(cumulative_points_by_participant_day)
    # Get all unique dates
    all_dates = cumulative_points_by_participant_day.values
      .flat_map(&:keys)
      .uniq
      .map { |d_str|
        begin
          Date.parse(d_str)
        rescue ArgumentError
          nil
        end
      }.compact
      .sort

    chart_labels = all_dates.map { |date| date.strftime("%d %b") }
    chart_cumulative_data = Hash.new { |h, k| h[k] = {} }
    
    # Get participants from the input data keys
    participant_names = cumulative_points_by_participant_day.keys

    participant_names.each do |participant_name|
      participant_data = cumulative_points_by_participant_day[participant_name] || {}
      last_known_points = 0

      all_dates.each do |date|
        date_key = date.to_s # Ensure consistent string format
        formatted_date = date.strftime("%d %b")

        if participant_data.key?(date_key)
          # The cumulative data now already contains the true cumulative values
          last_known_points = participant_data[date_key]
        end

        chart_cumulative_data[participant_name][formatted_date] = last_known_points
      end
    end

    { chart_labels: chart_labels, chart_cumulative_data: chart_cumulative_data }
  end

  private

  attr_reader :user, :household, :participants, :interval, :start_date, :end_date, :date_range

  def calculate_date_range(interval, start_date = nil, end_date = nil)
    # If custom date range is provided, use it
    if start_date.present? && end_date.present?
      begin
        start_time = Date.parse(start_date).beginning_of_day
        end_time = Date.parse(end_date).end_of_day
        return start_time..end_time
      rescue ArgumentError
        # Fall back to preset intervals if dates are invalid
      end
    end

    # Use preset intervals
    case interval
    when "1week"
      1.week.ago..Time.current
    when "1month"
      1.month.ago..Time.current
    when "6months"
      6.months.ago..Time.current
    when "1year"
      1.year.ago..Time.current
    when "all", nil
      nil # No date filtering for 'all' or when no interval specified
    else
      nil
    end
  end

  def apply_date_filter(query)
    return query unless date_range
    query.where(created_at: date_range)
  end
end
