# frozen_string_literal: true

# Service class responsible for generating ChatGPT analysis prompts
# based on household participant data and task completion patterns.
#
# Usage:
#   service = ChatGptPromptService.new(household)
#   prompt = service.generate_prompt
#
class ChatGptPromptService
  def initialize(household)
    @household = household
    raise ArgumentError, "Household cannot be nil" if household.nil?
  end

  # Generates a comprehensive ChatGPT prompt with participant analysis data
  #
  # @return [String] The formatted prompt ready for ChatGPT analysis
  # @raise [StandardError] If prompt generation fails
  def generate_prompt
    validate_household!

    participants_data = build_participants_data

    if participants_data.empty?
      return build_empty_household_prompt
    end

    json_data = participants_data.to_json
    build_chatgpt_prompt(json_data)
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error "Database error in ChatGPT prompt generation: #{e.message}"
    raise StandardError, "Database error occurred while generating analysis data"
  rescue JSON::GeneratorError => e
    Rails.logger.error "JSON generation error in ChatGPT prompt: #{e.message}"
    raise StandardError, "Data formatting error occurred"
  end

  private

  attr_reader :household

  # Validates that the household is in a valid state for analysis
  #
  # @raise [StandardError] If household validation fails
  def validate_household!
    unless household.persisted?
      raise StandardError, "Household must be saved to database"
    end

    unless household.respond_to?(:participants)
      raise StandardError, "Household must have participants association"
    end
  end

  # Generates a prompt for households with no active participants
  #
  # @return [String] Informational prompt about empty household in German
  def build_empty_household_prompt
    [
      "Hallo ChatGPT,",
      "",
      "dieser Haushalt hat derzeit keine aktiven Teilnehmer.",
      "",
      "Um mit der Analyse der Haushalts-Aufgabenverwaltung zu beginnen:",
      "1. Fügen Sie Teilnehmer zu Ihrem Haushalt hinzu",
      "2. Erstellen Sie einige Aufgaben für die Teilnehmer",
      "3. Lassen Sie Teilnehmer Aufgaben erledigen, um Daten zu generieren",
      "4. Kehren Sie hierher zurück für personalisierte Einblicke und Empfehlungen",
      "",
      "Sobald Sie Aktivitätsdaten der Teilnehmer haben, kann ich eine detaillierte Analyse " \
      "und Vorschläge zur Optimierung Ihrer Haushalts-Aufgabenverwaltung bereitstellen."
    ].join("\n")
  end

  # Builds structured data for all active participants
  #
  # @return [Array<Hash>] Array of participant data hashes
  def build_participants_data
    household.participants.active.includes(
      action_participants: { action: :task }
    ).map.with_index(1) do |participant, index|
      build_participant_data(participant, index)
    end
  end

  # Builds comprehensive data for a single participant
  #
  # @param participant [Participant] The participant to analyze
  # @param index [Integer] The anonymized index for this participant
  # @return [Hash] Structured participant data
  def build_participant_data(participant, index)
    completed_actions = participant.action_participants.includes(action: :task)
    
    # Calculate detailed point breakdown
    total_points = participant.total_points.to_f
    base_points = participant.base_points.to_f
    bonus_points = participant.bonus_points_total.to_f
    
    # Calculate betting statistics
    bet_costs = participant.bets.sum(:cost).to_f
    
    # Calculate streak statistics
    current_streak = participant.streak.to_i
    streak_bonus_count = participant.action_participants.where(on_streak: true).count
    
    {
      participant_id: participant.id,
      name: anonymized_name(index),
      total_points: total_points,
      base_points: base_points,
      bonus_points: bonus_points,
      bet_costs: bet_costs,
      net_bonus_points: bonus_points - bet_costs,
      completed_tasks_count: completed_actions.count,
      average_points_per_task: calculate_average_points(total_points, completed_actions.count),
      average_base_points_per_task: calculate_average_points(base_points, completed_actions.count),
      current_streak: current_streak,
      streak_bonus_count: streak_bonus_count,
      is_on_streak: participant.on_streak,
      overdue_tasks_assigned_count: count_overdue_tasks,
      tasks_due_soon_count: count_tasks_due_soon,
      task_completion_breakdown: build_task_completion_breakdown(completed_actions),
      points_efficiency: calculate_points_efficiency(base_points, bonus_points)
    }
  end

  # Generates an anonymized participant name (A, B, C, etc.)
  #
  # @param index [Integer] The participant index (1-based)
  # @return [String] Anonymized name like "Participant A"
  def anonymized_name(index)
    "Participant #{('A'.ord + index - 1).chr}"
  end

  # Calculates average points per completed task
  #
  # @param total_points [BigDecimal] Total points earned
  # @param completed_count [Integer] Number of completed tasks
  # @return [Float] Average points per task, or 0 if no tasks completed
  def calculate_average_points(total_points, completed_count)
    return 0.0 if completed_count.zero?

    (total_points.to_f / completed_count).round(2)
  end

  # Calculates the efficiency ratio of bonus points to base points
  #
  # @param base_points [Float] Base points earned from tasks
  # @param bonus_points [Float] Bonus points earned (including streaks, minus bets)
  # @return [Float] Efficiency ratio (bonus/base), or 0 if no base points
  def calculate_points_efficiency(base_points, bonus_points)
    return 0.0 if base_points.zero?

    (bonus_points / base_points * 100).round(1)
  end

  # Counts tasks that are currently overdue
  #
  # @return [Integer] Number of overdue tasks
  def count_overdue_tasks
    household.tasks.active.count do |task|
      overdue_value = task.overdue
      overdue_value.is_a?(Integer) && overdue_value.negative?
    end
  end

  # Counts tasks that will be due soon (within 24 hours)
  #
  # @return [Integer] Number of tasks due soon
  def count_tasks_due_soon
    household.tasks.active.count do |task|
      overdue_value = task.overdue
      overdue_value.is_a?(Integer) && overdue_value >= 0 && overdue_value <= 1
    end
  end

  # Builds a breakdown of task completions by task title
  #
  # @param completed_actions [ActiveRecord::AssociationRelation] Completed action participants
  # @return [Hash] Task title => completion count mapping
  def build_task_completion_breakdown(completed_actions)
    completed_actions
      .group_by { |action_participant| action_participant.action.task.title }
      .transform_values(&:count)
  end

  # Constructs the final ChatGPT prompt with structured data using German layout
  #
  # @param json_data [String] JSON-formatted participant data
  # @return [String] Complete prompt for ChatGPT analysis in German format
  def build_chatgpt_prompt(json_data)
    [
      "Hallo ChatGPT,",
      "",
      "ich benötige Ihre Expertise, um die Dynamik der Aufgabenverwaltung in unserem Haushalt zu verstehen und zu verbessern. Ich habe Daten für unsere Haushaltsteilnehmer zusammengestellt, die deren Gesamtbeiträge, Erledigungsraten und eine detaillierte Aufschlüsselung der von jedem Einzelnen erledigten spezifischen Aufgaben enthalten.",
      "",
      "Bitte analysieren Sie die folgenden JSON-Daten, die unsere Haushaltsteilnehmer repräsentieren. Ihre Analyse sollte folgende Punkte umfassen:",
      "",
      "*   **Gesamtleistungsvergleich:** Heben Sie signifikante Unterschiede oder Ähnlichkeiten in den Gesamtpunkten, Basispunkten, Bonuspunkten, erledigten Aufgaben und durchschnittlichen Punkten pro Aufgabe zwischen den Teilnehmern hervor.",
      "*   **Aufgabenspezialisierung & Verteilung:** Erkennen Sie klare Aufgabenpräferenzen oder Spezialisierungen für jeden Teilnehmer basierend auf deren 'task_completion_breakdown'. Sind die Aufgaben gleichmäßig verteilt, oder übernehmen bestimmte Personen konsequent bestimmte Aufgaben?",
      "*   **Engagement & Konsistenz:** Was sagen 'current_streak', 'is_on_streak', 'streak_bonus_count' und 'overdue_tasks_assigned_count' über die Konsistenz und das Engagement jedes Teilnehmers aus?",
      "*   **Punkte-Effizienz:** Analysieren Sie die 'points_efficiency', 'base_points', 'bonus_points' und 'net_bonus_points' um zu verstehen, wie effektiv jeder Teilnehmer Bonuspunkte verdient und verwaltet.",
      "*   **Handlungsempfehlungen:** Basierend auf all dem, welche konkreten Schritte oder Strategien können wir implementieren, um:",
      "    *   Eine ausgewogenere Aufgabenverteilung zu fördern?",
      "    *   Motivation und Engagement für alle Teilnehmer zu steigern?",
      "    *   Bestehende Aufgabenspezialisierungen zu nutzen oder neue zu fördern?",
      "    *   Die Punkte-Effizienz und Bonussystem-Nutzung zu optimieren?",
      "    *   Potenzielle 'Engpässe' oder Bereiche geringer Beteiligung anzugehen?",
      "",
      "Hier sind die Daten der Haushaltsteilnehmer:",
      "",
      json_data,
      "",
      "Bitte geben Sie eine umfassende und praktische Antwort, die uns hilft, unser freiwilliges Aufgabenverwaltungssystem im Haushalt zu optimieren."
    ].join("\n")
  end
end