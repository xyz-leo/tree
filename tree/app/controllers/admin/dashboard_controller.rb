class Admin::DashboardController < Admin::BaseController
  def show
    @profile = Profile.instance
    @groups = LinkGroup.ordered.includes(:links)
  end
end
