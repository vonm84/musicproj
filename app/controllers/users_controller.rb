

def create
  @user = User.new(params[:user])
  if @user.save
    session[:user_id] = @user.id
    redirect_to user_steps_path
  else
    render :new
  end
end

