class LinksController < ApplicationController
  allow_unauthenticated_access

  def index
    @tree = LinkTree.load(params[:lang])
  end
end
