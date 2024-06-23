class PagesController < ApplicationController

    def home
       
        @participants = Participant.all()
        @tasks = Task.all()
        respond_to do |format|
            format.turbo_stream { flash.now[:notice] = "Date was successfully destroyed." }
            format.html
        end
    end
end
