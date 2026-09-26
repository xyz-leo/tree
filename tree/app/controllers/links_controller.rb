class LinksController < ApplicationController
  def index
    @tree = LinkTree.load(params[:lang])
  end
end
