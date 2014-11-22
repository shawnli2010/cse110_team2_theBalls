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
    @user = User.find(params[:id])   # Not necessary because of the method correct_user
  end

 def update
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
 end

  def index
    @users = User.paginate(page: params[:page])
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "Account Closed."
    redirect_to users_url
  end

  def balance
    @user = User.find(params[:id])
    @histories = Array.new      # Array of strings representing transaction histories
    History.all.each do |history|
      if history.user_id == @user.id
        if history.cd == 1
          @the_string = history.created_at.to_s().html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
          'Credit'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.amount.to_s().html_safe + 
          '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
          'CheckingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.balance.to_s() +
          '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe +
          'SavingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.sbalance.to_s()
        elsif history.cd == 2
          @the_string = history.created_at.to_s().html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
          'Debit'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.amount.to_s().html_safe + 
          '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
          'CheckingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.balance.to_s() +
          '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe +
          'SavingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.sbalance.to_s()
        elsif history.cd == 3
          @the_string = history.created_at.to_s().html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
          'Trans C --> S'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.amount.to_s().html_safe + 
          '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
          'CheckingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.balance.to_s() +
          '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe +
          'SavingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.sbalance.to_s()
        elsif history.cd == 4
          @the_string = history.created_at.to_s().html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
          'Trans S --> C'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.amount.to_s().html_safe + 
          '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
          'CheckingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.balance.to_s() +
          '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe +
          'SavingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.sbalance.to_s()
        end

        @histories.push(@the_string)
      end
     end
  end

  def process_cd
    @user = User.find(params[:id])
    @history = History.new
    @amount = params[:amount]  # The amount of money that is credited or debited to the account
    @cd = 0     # The flag to determine whether it is an action of credit or debit
    if params[:credit]
      @cd = 1
      @balance = @user.balance + @amount.to_f
    elsif params[:debit]
      @cd = 2
      @balance = @user.balance - @amount.to_f
      if @balance < 0
        flash[:error] = "Transaction is failed"
        flash[:notice] = "You cannot withdrawl more than what is now in your account"
        redirect_to balance_user_path(@user) and return
      end
    end

    if @user.update_attribute(:balance, @balance)
      flash[:success] = "Transaction is successful"

      @history.update_attributes(:user_id => @user.id, :balance => @user.balance,
                                 :sbalance => @user.sbalance, :cd => @cd, :amount => @amount)

      redirect_to balance_user_path(@user)
    else
      render 'balance'
    end
  end

  def transfer
  end

  def process_transfer
    if is_admin?
      # For transaction history
      @sHistory = History.new
      @dHistory = History.new

      # Get the email from view
      @sEmail = params[:source_email]
      @dEmail = params[:dest_email]

      # Find the two customers by their email
      if @sUser = User.find_by_email(@sEmail)
      else
        flash[:error] = "Cannot find source user, please make sure the email is correct"
        redirect_to transfer_user_path and return
      end

      if @dUser = User.find_by_email(@dEmail)
      else
        flash[:error] = "Cannot find destination user, please make sure the email is correct"
        redirect_to transfer_user_path and return
      end

      # Get the transfer amount from view
      @amount = params[:amount].to_f

      # Check for balance for the source account
      if(@amount > @sUser.balance)
        flash[:error] = "Cannot transfer because the source account does not have enough balance"
        redirect_to transfer_user_path and return
      else
        @newSBalance = @sUser.balance - @amount
        @newDBalance = @dUser.balance + @amount

        @sUser.update_attribute(:balance, @newSBalance)
        @dUser.update_attribute(:balance, @newDBalance)
        flash[:success] = "Transfer is completed"

        @sHistory.update_attributes(:user_id => @sUser.id, :balance => @sUser.balance,
                                     :cd => 2, :amount => @amount)

        @dHistory.update_attributes(:user_id => @dUser.id, :balance => @dUser.balance,
                                     :cd => 1, :amount => @amount)

        redirect_to transfer_user_path
      end
    else
        @history = History.new

        @amount = params[:amount].to_f
        @customer = User.find(params[:id])
        @cBalance = @customer.balance
        @sBalance = @customer.sbalance

        # Check whether it is from checking to saving
        # or from saving to checking
        if params[:cToS]
          if (@amount > @cBalance)
            flash[:error] = "Checking account does not have enough balance"
            redirect_to transfer_user_path and return
          else
            @cBalance = @customer.balance - @amount
            @sBalance = @customer.sbalance + @amount
            @customer.update_attributes(:balance => @cBalance, :sbalance => @sBalance)
            flash[:success] = "Transfer is completed"

            @history.update_attributes(:user_id => @customer.id, :balance => @customer.balance,
                    :sbalance => @customer.sbalance, :cd => 3, :amount => @amount)

            redirect_to transfer_user_path and return
          end
        elsif params[:sToC]
          if (@amount > @sBalance)
            flash[:error] = "Saving account does not have enough balance"
            redirect_to transfer_user_path and return
          else
            @sBalance = @customer.sbalance - @amount
            @cBalance = @customer.balance + @amount
            @customer.update_attributes(:balance => @cBalance, :sbalance => @sBalance)
            flash[:success] = "Transfer is completed"

            @history.update_attributes(:user_id => @customer.id, :balance => @customer.balance,
                    :sbalance => @customer.sbalance, :cd => 4, :amount => @amount)

            redirect_to transfer_user_path and return
          end
        end  
    end
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
