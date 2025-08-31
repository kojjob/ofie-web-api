# Controller to handle sitemap generation and serving
class SitemapController < ApplicationController
  skip_before_action :authenticate_request
  
  def index
    @sitemap = SitemapGeneratorService.new(request.host_with_port).generate
    
    respond_to do |format|
      format.xml { render xml: @sitemap }
    end
  end
end