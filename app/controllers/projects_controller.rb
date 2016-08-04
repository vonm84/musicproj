def index
  @projects = Project.search(params[:search])
end