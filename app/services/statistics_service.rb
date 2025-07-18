class StatisticsService
  def initialize(user, participants = nil)
    @user = user
    @participants = participants || user.participants.includes(actions: :task)
  end

  def generate_task_completion_data
    ActionParticipant
      .joins(action: :task, participant: :user)
      .where(users: { id: user.id })
      .group("tasks.title", "participants.name")
      .select(
        "tasks.title AS task_title",
        "participants.name AS participant_name",
        "COUNT(action_participants.id) AS actions_count",
        "tasks.worth AS task_worth"
      )
      .where("tasks.archived = ?", false)
      .order("tasks.title", "participants.name")
  end

  def generate_task_completion_by_participant
    ActionParticipant
      .joins(participant: :user)
      .where(users: { id: user.id })
      .joins(:participant)
      .group("participants.name")
      .count
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
    ActionParticipant
      .joins(action: :task, participant: :user)
      .where(users: { id: user.id })
      .group("participants.name")
      .sum("action_participants.points_earned")
  end

  def generate_task_popularity
    ActionParticipant
      .joins(action: :task, participant: :user)
      .where(users: { id: user.id })
      .group("tasks.title")
      .count
      .sort_by { |_, count| -count }
      .to_h
  end

  def generate_activity_over_time
    ActionParticipant
      .joins(participant: :user)
      .where(users: { id: user.id })
      .group_by_day(:created_at, last: 30)
      .count
  end

  def generate_participant_activity
    ActionParticipant
      .joins(participant: :user)
      .where(users: { id: user.id })
      .group("participants.name")
      .group_by_day(:created_at, last: 30)
      .count
  end

  def generate_points_by_day
    ActionParticipant
      .joins(action: :task, participant: :user)
      .where(users: { id: user.id })
      .group_by_day(:created_at, last: 30)
      .sum("action_participants.points_earned")
  end

  def generate_bonus_points_by_day
    ActionParticipant
      .joins(participant: :user)
      .where(users: { id: user.id })
      .where.not(bonus_points: nil)
      .group_by_day(:created_at, last: 30)
      .sum("action_participants.bonus_points")
  end

  def generate_cumulative_bonus_data
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

    cumulative_data = ActionParticipant
      .joins(participant: :user)
      .where(users: { id: user.id })
      .select(select_cumulative_sql)
      .where.not(bonus_points: nil)
      .order("participant_name", "action_date")

    # Process into nested hash
    cumulative_bonus_by_participant_day = Hash.new { |h, k| h[k] = {} }
    cumulative_data.each do |record|
      date_key = record.action_date
      cumulative_bonus_by_participant_day[record.participant_name][date_key] = record.cumulative_bonus_points
    end

    cumulative_bonus_by_participant_day
  end

  def generate_cumulative_data
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

    cumulative_data = ActionParticipant
      .joins(action: :task, participant: :user)
      .where(users: { id: user.id })
      .select(select_cumulative_sql)
      .where("action_participants.points_earned > 0")
      .order("participant_name", "action_date")

    # Process into nested hash
    cumulative_points_by_participant_day = Hash.new { |h, k| h[k] = {} }
    cumulative_data.each do |record|
      date_key = record.action_date
      cumulative_points_by_participant_day[record.participant_name][date_key] = record.cumulative_points
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
    last_known_points = Hash.new(0)

    # Fix: Get participants from the input data keys
    participant_names = cumulative_points_by_participant_day.keys

    participant_names.each do |participant_name|
      last_known_points[participant_name] = 0
      participant_data = cumulative_points_by_participant_day[participant_name] || {}

      all_dates.each do |date|
        date_key = date.to_s # Ensure consistent string format
        formatted_date = date.strftime("%d %b")

        if participant_data.key?(date_key)
          last_known_points[participant_name] = participant_data[date_key]
        end

        chart_cumulative_data[participant_name][formatted_date] = last_known_points[participant_name]
      end
    end

    { chart_labels: chart_labels, chart_cumulative_data: chart_cumulative_data }
  end

  private

  attr_reader :user, :participants
end
