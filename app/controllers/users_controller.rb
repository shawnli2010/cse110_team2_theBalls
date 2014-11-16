class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :update]
  before_action :correct_user,   only: :index
  before_action :admin_user,     only: :destroy

  def show
	   if signed_in?
      @user = User.find(params[:id])
    else
      flash[:notice] = "Please sign in."
      redirect_to signin_url
    end
  end

  def new
  	@user = User.new
  end

  def create
    @user = User.new(user_params)    
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to the CSE110 Team 2 EveryOneRich Bank!"
      redirect_to @user
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])   
  end

  def update
    @user = User.find(params[:id])    # Not necessary because of the method correct_user
    @amount = 0
    if params[:credit]
      @credit = params[:user][:balance]   #:balance in this line means amount of money
      @balance = @user.balance + @credit.to_f
      #@amount = @credit
    elsif params[:debit]
      @debit = params[:user][:balance]    #:balance in this line means amount of money
      @balance = @user.balance - @debit.to_f
      if @balance < 0
        @balance = @user.balance
        flash[:error] = "Transaction is failed"
        flash[:notice] = "You cannot withdrawl more than what is now in your account"
        redirect_to edit_user_path(@user) and return
      #else
        #@amount = -@debit
      end

    end

    if @user.update_attribute(:balance, @balance)
      flash[:success] = "Transaction is successful"
      #@user.histories.build(amout: @amount, date: Time.now, balance: @balance, user_id:@user.id)
      #@history = History.new(amout: @amount, date: Time.now, balance: @balance, user_id:@user.id)
      redirect_to edit_user_path(@user)
    else
      render 'edit'
    end
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User destroyed."
    redirect_to users_url
  end

   private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

     # Before filters

    def signed_in_user
      unless signed_in?
        store_location
        flash[:notice] = "Please sign in."
        redirect_to signin_url
      end    
    end

    def correct_user
      redirect_to(root_path) unless is_admin?
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end
