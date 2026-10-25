class CategoriesController < Public::BaseController
  before_action { fresh_when weak_etag: Peak.release.sha, public: true }

  def index
    @letters = Peak::Category::Group.letters
    @groups  = Peak::Category::Group.lettered[params[:l]] || Peak::Category::Group.all
  end

  def show
    @category = Peak::Category.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to categories_path, alert: "That category doesn't exist"
  end
end
