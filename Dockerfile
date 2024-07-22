# Use a Ruby 3.3 image as the base
FROM ruby:3.3-alpine

# Create app directory and set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock to install dependencies
COPY Gemfile Gemfile.lock /app/

# Install dependencies
RUN bundle install

# Copy the rest of the application code
COPY . /app

# Expose port 3000 for the Rails server
EXPOSE 3000

# Command to start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
