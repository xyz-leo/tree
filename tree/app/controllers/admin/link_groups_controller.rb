class Admin::LinkGroupsController < Admin::BaseController
  before_action :set_link_group, only: %i[ edit update destroy ]

  def new
    @link_group = LinkGroup.new
  end

  def create
    @link_group = LinkGroup.new(link_group_params)

    if @link_group.save
      redirect_to admin_root_path, notice: "Group added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @link_group.update(link_group_params)
      redirect_to admin_root_path, notice: "Group saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @link_group.destroy!
    redirect_to admin_root_path, notice: "Group deleted.", status: :see_other
  end

  private
    def set_link_group
      @link_group = LinkGroup.find(params.expect(:id))
    end

    def link_group_params
      params.expect(link_group: %i[ label_pt label_en position ])
    end
end
