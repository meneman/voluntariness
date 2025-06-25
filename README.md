# Voluntariness

A gamified household task management application that helps families track task completion, earn points, and view contribution statistics. Built with Ruby on Rails 8.0 and modern web technologies.

## Features

- **Task Management**: Create tasks with customizable point values and intervals
- **Participant Tracking**: Manage household members with unique avatars and colors
- **Points System**: Earn points for task completion with bonus rewards
- **Streak Bonuses**: Get bonus points for consecutive daily participation
- **Overdue Bonuses**: Extra points for completing overdue tasks
- **Statistics & Analytics**: Comprehensive charts and data visualization
- **Real-time Updates**: Live updates using Turbo Streams
- **Archive System**: Soft delete for tasks and participants
- **Multi-user Support**: Each user manages their own household

## Technology Stack

- **Backend**: Ruby on Rails 8.0.1
- **Database**: SQLite 3 (development & production)
- **Frontend**: Stimulus + Turbo for SPA-like experience
- **Styling**: TailwindCSS 3.3
- **Charts**: Chart.js for data visualization
- **Authentication**: Devise 4.9
- **Deployment**: Docker + Kamal
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache

## Prerequisites

- Ruby 3.1+ 
- Node.js 18+
- SQLite 3

## Installation

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/meneman/voluntariness.git
   cd voluntariness
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Setup database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Start the development server**
   ```bash
   ./bin/dev
   ```

5. **Access the application**
   Open your browser to `http://localhost:3000`

### Docker Deployment

1. **Build the Docker image**
   ```bash
   docker build -t voluntariness .
   ```

2. **Deploy with Kamal**
   ```bash
   kamal setup
   kamal deploy
   ```

## Usage

### Getting Started

1. **Create an Account**: Register with your email and password
2. **Add Participants**: Create profiles for household members with names, colors, and avatars
3. **Create Tasks**: Define household tasks with:
   - Title and description
   - Point values (how much each completion is worth)
   - Intervals (how often the task should be done)
4. **Complete Tasks**: Mark tasks as complete to earn points
5. **View Statistics**: Check the statistics page for detailed analytics

### Points System

- **Base Points**: Earned by completing tasks based on their assigned value
- **Streak Bonuses**: Additional points for consecutive daily participation (configurable threshold)
- **Overdue Bonuses**: Extra points calculated for completing tasks past their due date
- **Formula**: `Final Points = Base Points + Streak Bonus + Overdue Bonus`

### Configuration

Users can customize their experience through the settings page:

- **Enable/Disable Streak Bonuses**: Toggle streak-based rewards
- **Streak Threshold**: Set how many consecutive days are required for bonus points
- **Enable/Disable Overdue Bonuses**: Toggle extra points for late completions

## Development

### Running Tests

```bash
rails test
```

### Code Quality

```bash
# Run linter
bundle exec rubocop

# Run security scanner
bundle exec brakeman

# Check for outdated gems
bundle outdated
```

### Database Migrations

```bash
# Create new migration
rails generate migration MigrationName

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback
```

## API

The application provides RESTful endpoints for:

- `/tasks` - Task management
- `/participants` - Participant management  
- `/actions` - Task completion tracking
- `/settings` - User preference management
- `/statistics` - Analytics data

All endpoints support both HTML and Turbo Stream formats for real-time updates.

## Architecture

### Models

- **User**: Devise-based authentication with user preferences
- **Task**: Household tasks with points, intervals, and archiving
- **Participant**: Household members with avatars and colors
- **Action**: Task completion records with bonus point tracking

### Key Services

- **StatisticsService**: Handles complex analytics and chart data generation
- **VoluntarinessConstants**: Application-wide configuration constants

### Security

- CSRF protection enabled
- SQL injection prevention via parameterized queries
- XSS protection with HTML escaping
- User data isolation and authorization

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## Support

For bug reports and feature requests, please use the [GitHub Issues](https://github.com/meneman/voluntariness/issues) page.
