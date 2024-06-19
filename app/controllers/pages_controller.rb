class PagesController < ApplicationController

    def home
        @actions = Action.all()
        @participants = Participant.all()
        @tasks = Task.all()
    end
end
