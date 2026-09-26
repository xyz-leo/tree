class Admin::LinksController < Admin::BaseController
  before_action :set_link, only: %i[ edit update destroy ]

  def new
    @link = link_group.links.new
  end

  def create
    @link = link_group.links.new(link_params)

    if @link.save
      redirect_to admin_root_path, notice: "Link added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @link.update(link_params)
      redirect_to admin_root_path, notice: "Link saved."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @link.destroy!
    redirect_to admin_root_path, notice: "Link deleted.", status: :see_other
  end

  private
    def link_group
      @link_group ||= LinkGroup.find(params.expect(:link_group_id))
    end

    def set_link
      @link = Link.find(params.expect(:id))
    end

    def link_params
      params.expect(link: %i[ title url hint_pt hint_en position link_group_id ])
    end
end
