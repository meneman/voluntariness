class TasksController < ApplicationController

      
    before_action :set_task, except: [:index, :new, :create, :cancel]

    def index
         @tasks = current_user.task.all()
         respond_to do |format|
            format.html
            format.turbo_stream
          end
    end

    def show
        @participants = current_user.participants
    end

    def new 
        @task = current_user.tasks.build
        respond_to do |format|
            format.turbo_stream
            format.html
        end
    end


    def archive
        @task.update(archived: !@task.archived)
        respond_to do |format|
            format.html {}
            format.turbo_stream {}
        end
    end


    def edit 
      
    end

    def cancel 
        # headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
        # respond_to do |format|
        #     format.html {}
        #     format.turbo_stream {}
        # end
    end

    def create 
        @task = current_user.tasks.build(task_params)
        @participants = current_user.participants
        if @task.save
            respond_to do |format|
                format.turbo_stream {}
                format.html {}
            end
        else
            render :new, status: :unprocessable_entity
        end
    end

    def update 
        
        if @task.update(task_params)
            redirect_to @task
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
        
        @task = current_user.tasks.find(params[:id])
        
        
    # rescue ActiveRecord::RecordNotFound
    #     redirect_to root_path
    end 
    

end
