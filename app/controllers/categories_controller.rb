class CategoriesController < Public::BaseController
  before_action :set_category, only: :show
  before_action -> { fresh_when weak_etag: Peak.release.sha, public: true }, only: :index

  def index
    @letters = Peak::Category::Group.letters
    @groups  = Peak::Category::Group.lettered[params[:l]] || Peak::Category::Group.all
  end

  def show
    @versions = set_stable_index(:@rubygems).versions.for(@category.projects)
    fresh_when @versions, public: true

    @versions = @versions.pure.as_byline.distinct_on_gem.order(ref: :desc)
  end

  private
    def set_category
      @category = Peak::Category[params[:id]] or redirect_to categories_path, alert: "That category doesn't exist"
    end
end
