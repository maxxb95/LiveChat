class ApplicationController < ActionController::API
  # Handle ActiveRecord errors
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # Handle parameter errors
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  # Handle general exceptions
  rescue_from StandardError, with: :render_internal_server_error

  private

  def render_unprocessable_entity(exception)
    Rails.logger.error("Unprocessable Entity: #{exception.message}")
    render json: { error: 'Validation failed', message: exception.message }, status: :unprocessable_entity
  end

  def render_not_found(exception)
    Rails.logger.error("Not Found: #{exception.message}")
    render json: { error: 'Resource not found', message: exception.message }, status: :not_found
  end

  def render_bad_request(exception)
    Rails.logger.error("Bad Request: #{exception.message}")
    render json: { error: 'Invalid request parameters', message: exception.message }, status: :bad_request
  end

  def render_internal_server_error(exception)
    Rails.logger.error("Internal Server Error: #{exception.class.name} - #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))
    
    error_message = Rails.env.development? ? exception.message : 'An unexpected error occurred'
    render json: { error: 'Internal server error', message: error_message }, status: :internal_server_error
  end
end
