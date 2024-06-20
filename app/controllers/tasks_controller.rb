class TasksController < ApplicationController

      
    before_action :set_task, except: [:index, :new, :create]

    def index
         @tasks = Task.all()
         respond_to do |format|
            format.html
            format.turbo_stream
          end
    end

    def show
    end

    def new 
        @task = Task.new
        # respond_to do |format|
        #     format.html
        #     format.turbo_stream
        # end
    end

    def edit 
      
    end

    def create 
        @task = Task.new(task_params)
        if @task.save
            redirect_to @task
            respond_to do |format|
                format.html
                format.turbo_stream
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
    end

    private
    
    def task_params 
        params.require(:task).permit(:title, :worth, :interval, :description)
    end

    def set_task
        @task = Task.find(params[:id]) 
        
        
    rescue ActiveRecord::RecordNotFound
        redirect_to root_path
    end 
    

end
