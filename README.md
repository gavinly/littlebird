# Littlebird Intents Explorer

A Phoenix-based web application for managing and exploring intents. The application provides a LiveView interface for creating, viewing, and managing intents with expiration times.

## Environments

- **Production**: [`littlebird.fly.dev`](https://littlebird.fly.dev)
- **Staging**: [`fledgling.fly.dev`](https://fledgling.fly.dev)

## Development Setup

1. Install dependencies:
   ```bash
   mix setup
   ```

2. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

3. Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Deployment

The application is deployed on Fly.io. The deployment process is automated through the following steps:

1. Ensure you have the Fly.io CLI installed:
   ```bash
   brew install flyctl
   ```

2. Login to Fly.io:
   ```bash
   flyctl auth login
   ```

3. Deploy to staging (fledgling):
   ```bash
   flyctl deploy --app fledgling
   ```

4. Deploy to production (littlebird):
   ```bash
   flyctl deploy --app littlebird
   ```

## Features

- **Intent Management**: Create and view intents through a LiveView interface
- **Expiration Times**: Set expiration times for intents in minutes
- **Real-time Updates**: Live updates of intent statuses
- **Health Checks**: Endpoint at `/health` for monitoring
- **ETS-based Storage**: Fast in-memory storage for intents

## Repository Structure

- `lib/deploy_hello/intent_store.ex` - Intent storage and management
- `lib/deploy_hello_web/live/intent_live.ex` - LiveView for intent interface
- `lib/deploy_hello_web/controllers/` - Controllers for API endpoints
- `lib/deploy_hello_web/components/` - Reusable UI components

## Configuration

The application uses the following environment variables:

- `PORT` - The port to run the server on (default: 8080)
- `PHX_HOST` - The host for the Phoenix endpoint
- `SECRET_KEY_BASE` - Secret key for session encryption
- `FLY_APP_NAME` - The Fly.io application name

## Branch Strategy

- `fly-deployment` - Main deployment branch containing the working Fly.io configuration
- `main` - Original repository branch (currently not in use)

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
- [Fly.io Documentation](https://fly.io/docs/)
