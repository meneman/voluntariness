class BlogPostsController < ApplicationController
    
    before_action :authenticate_user!, except: [:index, :show]
    before_action :set_blog_post, except: [:index, :new, :create]

    def index
        @blog_posts = BlogPost.all
    end


    def show
    rescue ActiveRecord::RecordNotFound
        redirect_to root_path
    end

    def new 
        @blog_post = BlogPost.new
    end

    def edit 
        @blog_post = BlogPost.find(params[:id])
    end

    def create 
  
        if @blog_post.save
            redirect_to @blog_post
        else
            render :new, status: :unprocessable_entity
        end
    end

    def update 

        if @blog_post.update(blog_post_params)
            redirect_to @blog_post
        else 
            render :edit, status: :unprocessable_entity
        end
    end


    def destroy 

        @blog_post.destroy()
        redirect_to :root
    end

    private
    
    def blog_post_params 
        params.require(:blog_post).permit(:title, :body)
    end

    def set_blog_post
        @blog_post = BlogPost.find(params[:id])
    end 

    def authenticate_user!
        redirect_to new_user_session_path, alert: "you must sign in!" unless  user_signed_in?
          
    end
    

end
