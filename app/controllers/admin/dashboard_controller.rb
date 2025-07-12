class Admin::DashboardController < ApplicationController
  before_action :require_admin!

  def index
    @users_count = User.count
    @premium_users_count = User.where.not(subscription_plan: "free").count
    @recent_users = User.order(created_at: :desc).limit(5)
    @tasks_count = Task.count
    @actions_count = Action.count
  end
end
