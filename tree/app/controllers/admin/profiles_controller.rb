class Admin::ProfilesController < Admin::BaseController
  before_action :set_profile

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to admin_root_path, notice: "Profile saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_profile
      @profile = Profile.instance
    end

    def profile_params
      params.expect(profile: %i[ name handle bio_pt bio_en ])
    end
end
