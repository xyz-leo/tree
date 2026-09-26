class LinksController < ApplicationController
  allow_unauthenticated_access

  def index
    @lang = params[:lang]
    @profile = Profile.instance
    @groups = LinkGroup.ordered.includes(:links).select { it.links.any? }
  end
end
