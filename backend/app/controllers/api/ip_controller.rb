module Api
  class IpController < ApplicationController
    def show
      ip = request.remote_ip
      normalized_ip = normalize_ip_safely(ip)
      
      render json: {
        ip_address: ip,
        normalized_ip: normalized_ip
      }
    rescue StandardError => e
      Rails.logger.error("Error in ip#show: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: {
        ip_address: ip,
        normalized_ip: nil,
        error: 'Failed to normalize IP address'
      }, status: :ok # Still return 200 with partial data
    end

    private

    def normalize_ip_safely(ip_address)
      IpNormalizer.normalize(ip_address)
    rescue StandardError => e
      Rails.logger.error("Error normalizing IP address: #{e.message}")
      nil
    end
  end
end

