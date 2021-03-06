module SessionsHelper
  def sign_in(user)
    # Check whether this user has been closed or not
    if user.existence == false
      flash[:error] = "The account has been closed"
      redirect_to signin_url 
    else
      remember_token = User.new_remember_token
      cookies.permanent[:remember_token] = remember_token
      user.update_attribute(:remember_token, User.hash(remember_token))
      self.current_user = user
      redirect_to user
    end
  end

   def current_user=(user)
    @current_user = user
  end

   def current_user
    remember_token = User.hash(cookies[:remember_token])
    @current_user ||= User.find_by(remember_token: remember_token)
  end

  def current_user?(user)
    user == current_user
  end

  def signed_in?
    !current_user.nil?
  end

  def sign_out
    current_user.update_attribute(:remember_token,
                                  User.hash(User.new_remember_token))
    self.current_user = nil
    cookies.delete(:remember_token)
  end

  # def redirect_back_or(default)
  #   redirect_to(session[:return_to] || default)
  #   session.delete(:return_to)
  # end

  def store_location
    session[:return_to] = request.fullpath if request.get?
  end

  def is_admin?
    current_user.admin
  end

  def is_admin_profile_page
    current_page?('http://localhost:3000/users/1')
  end
end
