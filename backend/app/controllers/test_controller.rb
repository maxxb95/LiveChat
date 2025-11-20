class TestController < ApplicationController
  def index
    render json: {
      message: "GET request successful!",
      timestamp: Time.current.iso8601,
      method: "GET"
    }, status: :ok
  end

  def create
    render json: {
      message: "POST request successful!",
      received_data: params.except(:controller, :action),
      timestamp: Time.current.iso8601,
      method: "POST"
    }, status: :ok
  end
end

