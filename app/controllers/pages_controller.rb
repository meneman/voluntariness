class PagesController < ApplicationController

    def home
       
        @participants = Participant.all()
        @tasks = Task.all()
    end
end
