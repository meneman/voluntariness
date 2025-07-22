class TasksController < ApplicationController
    before_action :set_task, except: [ :index, :new, :create, :cancel ]


    def show
        @participants = current_household.participants
    end

    def new
        @task = current_household.tasks.build
        respond_to do |format|
            format.turbo_stream
            format.html
        end
    end


    def archive
        @task.update(archived: true)
        respond_to do |format|
            format.html { redirect_to tasks_path }
            format.turbo_stream { }
        end
    end

    def unarchive
        unless current_household.can_add_task?
            respond_to do |format|
                format.html { 
                    flash[:alert] = "This household already has the maximum of 30 active tasks. Cannot unarchive."
                    redirect_to tasks_path 
                }
                format.turbo_stream {
                    flash.now[:alert] = "This household already has the maximum of 30 active tasks. Cannot unarchive."
                    render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
                }
            end
            return
        end

        @task.update(archived: false)
        respond_to do |format|
            format.html { redirect_to tasks_path }
            format.turbo_stream { }
        end
    end


    def edit
    end

    def cancel
    end

    def create
        unless current_household.can_add_task?
            respond_to do |format|
                format.turbo_stream { 
                    flash.now[:alert] = "This household can only have a maximum of 30 active tasks."
                    render :new, status: :unprocessable_entity 
                }
                format.html { 
                    flash[:alert] = "This household can only have a maximum of 30 active tasks."
                    redirect_to tasks_path 
                }
            end
            return
        end

        @task = current_household.tasks.build(task_params)
        @participants = current_household.participants
        if @task.save
            respond_to do |format|
                format.turbo_stream { }
                format.html { redirect_to @task }
            end
        else
            respond_to do |format|
                format.turbo_stream { render :new, status: :unprocessable_entity }
                format.html { render :new, status: :unprocessable_entity }
            end
        end
    end

    def update
        if @task.update(task_params)
            # Check if this is a sortable position update
            if params[:task][:position] && request.xhr?
                head :ok  # Return 200 OK for AJAX sortable requests
            else
                redirect_to @task
            end
        else
            render :edit, status: :unprocessable_entity
        end
    end


    def destroy
        @task.destroy()

        respond_to do |format|
            format.html { redirect_to tasks_path }
            format.turbo_stream {  }
        end
    end

    private

    def task_params
        params.require(:task).permit(:title, :worth, :interval, :description, :position)
    end

    def set_task
        @task = current_household.tasks.find(params[:id])
    end
end
