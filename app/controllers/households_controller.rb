class HouseholdsController < ApplicationController
  before_action :set_household, except: [ :index, :new, :create, :switch_household, :join ]
  before_action :require_household_admin!, except: [ :index, :new, :create, :show, :switch_household, :join ]

  def index
    @households = current_user.households.includes(:users, :household_memberships)
    @current_household_membership = current_user.household_memberships.find_by(household: current_household)
  end

  def show
    @membership = current_user.household_memberships.find_by(household: @household)
    @members = @household.users.includes(:household_memberships)
    @tasks_count = @household.tasks.count
    @participants_count = @household.participants.count
  end

  def new
    @household = Household.new
  end

  def create
    unless current_user.can_create_household?
      redirect_to households_path, alert: "You can only create a maximum of 5 households."
      return
    end

    @household = Household.new(household_params)

    if @household.save
      # Create owner membership for current user
      HouseholdMembership.create!(
        user: current_user,
        household: @household,
        role: "owner",
        current_household: true
      )

      # Update current household for other memberships
      current_user.household_memberships.where.not(household: @household)
                  .update_all(current_household: false)

      # Create default tasks for the new household
      unless DefaultTasksService.create_default_tasks_for(@household)
        Rails.logger.warn "Failed to create default tasks for household #{@household.id}"
      end

      # Track household creation in PostHog
      is_first_household = current_user.households.count == 1
      PosthogService.track(current_user.id, 'household_created', {
        household_id: @household.id,
        household_name: @household.name,
        user_total_households: current_user.households.count,
        default_tasks_created: @household.tasks.count,
        is_first_household: is_first_household
      })
      
      # Track first household creation and onboarding completion
      if is_first_household
        PosthogService.track(current_user.id, 'first_household_created', {
          household_name: @household.name,
          days_since_signup: (Time.current - current_user.created_at) / 1.day
        })
        
        PosthogService.track(current_user.id, 'onboarding_completed', {
          completion_time_days: (Time.current - current_user.created_at) / 1.day,
          default_tasks_created: @household.tasks.count
        })
      end

      redirect_to @household, notice: "Household was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @household.update(household_params)
      redirect_to @household, notice: "Household was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Only allow owner to delete household
    membership = current_user.household_memberships.find_by(household: @household)
    unless membership&.owner?
      redirect_to households_path, alert: "Only household owners can delete households."
      return
    end

    # Don't allow deletion if it's the user's only household
    if current_user.households.count <= 1
      redirect_to households_path, alert: "You cannot delete your only household."
      return
    end

    @household.destroy

    # Set another household as current if this was the current one
    if current_household == @household
      current_user.set_current_household(current_user.households.first)
    end

    redirect_to households_path, notice: "Household was successfully deleted."
  end

  def switch_household
    @household = current_user.households.find(params[:id])
    @current_household = nil
    current_user.set_current_household(@household)
    current_user.reload # Reload user associations from database
    @households = current_user.households.includes(:household_memberships)

    respond_to do |format|
      format.turbo_stream { render :switch, notice: "Switched to #{@household.name}" }
      format.html { redirect_to households_path, notice: "Switched to #{@household.name}" }
    end
  end

  def join
    if request.post?
      unless current_user.can_join_household?
        flash.now[:alert] = "You can only join a maximum of 5 households."
        render :join
        return
      end

      @household = Household.find_by(invite_code: params[:invite_code])

      if @household.nil?
        flash.now[:alert] = "Invalid invite code."
        render :join
        return
      end

      if current_user.households.include?(@household)
        redirect_to @household, notice: "You are already a member of this household."
        return
      end

      HouseholdMembership.create!(
        user: current_user,
        household: @household,
        role: "member"
      )

      redirect_to households_path, notice: "Successfully joined #{@household.name}!"
    end
  end

  private

  def set_household
    @household = current_user.households.find(params[:id])
  end

  def household_params
    params.require(:household).permit(:name, :description)
  end

  def require_household_admin!
    membership = current_user.household_memberships.find_by(household: @household)
    unless membership&.can_manage_household?
      redirect_to households_path, alert: "You do not have permission to manage this household."
    end
  end
end
