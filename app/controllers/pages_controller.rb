class PagesController < ApplicationController
  def index
    @articles = Article.all
  end

  def contact
  end

  def about
  end
end
