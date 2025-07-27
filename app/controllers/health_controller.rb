class HealthController < ApplicationController
  skip_before_action :authenticate_request
  skip_before_action :verify_authenticity_token
  
  def show
    health_status = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || 'unknown',
      checks: perform_health_checks
    }
    
    if all_checks_passing?(health_status[:checks])
      render json: health_status, status: :ok
    else
      render json: health_status, status: :service_unavailable
    end
  end
  
  private
  
  def perform_health_checks
    {
      database: check_database,
      redis: check_redis,
      storage: check_storage,
      memory: check_memory,
      disk: check_disk_space
    }
  end
  
  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { status: 'healthy', response_time: measure_time { User.first } }
  rescue StandardError => e
    { status: 'unhealthy', error: e.message }
  end
  
  def check_redis
    if defined?(Redis) && Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
      Rails.cache.redis.ping
      { status: 'healthy', response_time: measure_time { Rails.cache.read('health_check') } }
    else
      { status: 'not_configured' }
    end
  rescue StandardError => e
    { status: 'unhealthy', error: e.message }
  end
  
  def check_storage
    if ActiveStorage::Blob.service.exist?('health_check')
      { status: 'healthy' }
    else
      # Try to write a test file
      ActiveStorage::Blob.service.upload('health_check', StringIO.new('test'))
      { status: 'healthy' }
    end
  rescue StandardError => e
    { status: 'unhealthy', error: e.message }
  end
  
  def check_memory
    memory_usage = get_memory_usage
    memory_limit = ENV.fetch('MEMORY_LIMIT_MB', '512').to_i
    
    if memory_usage < memory_limit * 0.9
      { status: 'healthy', usage_mb: memory_usage, limit_mb: memory_limit }
    else
      { status: 'warning', usage_mb: memory_usage, limit_mb: memory_limit }
    end
  end
  
  def check_disk_space
    disk_usage = get_disk_usage_percentage
    
    if disk_usage < 90
      { status: 'healthy', usage_percentage: disk_usage }
    else
      { status: 'warning', usage_percentage: disk_usage }
    end
  end
  
  def all_checks_passing?(checks)
    checks.values.all? { |check| check[:status] == 'healthy' || check[:status] == 'not_configured' }
  end
  
  def measure_time
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(2)
  end
  
  def get_memory_usage
    # Get current process memory usage in MB
    if File.exist?('/proc/self/status')
      File.read('/proc/self/status').match(/VmRSS:\s+(\d+)/)[1].to_i / 1024
    else
      # Fallback for non-Linux systems
      (`ps -o rss= -p #{Process.pid}`.to_i / 1024.0).round
    end
  rescue StandardError
    0
  end
  
  def get_disk_usage_percentage
    # Get disk usage percentage for the app directory
    output = `df -h #{Rails.root} | tail -1`
    output.split[4].to_i
  rescue StandardError
    0
  end
end