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
      # Create the default checking account for the newly registered customer
      @default_cAccount = Account.new

      @default_cAccount.update_attributes(:user_id => @user.id, :balance => 0, :acct_type => true, 
                                  :threshold => -1, :is_threshold => false, :is_receiving => true,
                                  :is_default_receiving => true )

      @user.update_attribute(:default_receiving_ID, @default_cAccount.id)
      

      # Automatically signed in after the user finish registered
      flash[:success] = "Welcome to the CSE110 Team 2 EveryOneRich Bank!"
      sign_in @user
    else
      render 'new'
    end
  end

  def set_receiving
    @user = User.find(params[:id])
    # Check whether the account exists in the database or not
    begin
      @account = Account.find(params[:acct_ID])
    rescue 
      flash[:error] = "Please input the correct account ID referring to the \"Your Accounts\" above"
      redirect_to balance_user_path and return     
    end
    # If the customer is not inputting the correct account ID
    if @account.user_id != @user.id
      flash[:error] = "Please input the correct account ID referring to the \"Your Accounts\" above"
      redirect_to balance_user_path and return
    end

    # Check whether the account has been closed or not
    if @account.existence == false
      flash[:error] = "The account is closed, please input another existed account"
      redirect_to balance_user_path and return
    end

    if params[:enable]
      @account.update_attribute(:is_receiving, true)
      if @account.is_default_receiving == true
        @account.update_attribute(:is_default_receiving, false)
        @user.update_attribute(:default_receiving_ID, -1)
        flash[:notice] = "You just closed your default receiving account, please set another account
                          to be the default receving account in order to receive transfer fund from
                          other customer"
      end
      flash[:success] = "Process completed"
      flash[:notice] = "Account with ID:" + params[:acct_ID] + " will be able to reveive transfer"
      redirect_to balance_user_path
    elsif params[:disable]
      @account.update_attribute(:is_receiving, false)
      flash[:success] = "Process completed"
      flash[:notice] = "Account with ID:" + params[:acct_ID] + " will NOT be able to reveive transfer"
      redirect_to balance_user_path
    end 
  end

  def set_threshold
    @user = User.find(params[:id])

    # Check whether the account exists in the database or not
      begin
        @account = Account.find(params[:acct_ID])
      rescue 
        flash[:error] = "Please input the correct account ID referring to the \"Your Accounts\" above"
        redirect_to balance_user_path and return     
      end
      # If the customer is not inputting the correct account ID
      if @account.user_id != @user.id
        flash[:error] = "Please input the correct account ID referring to the \"Your Accounts\" above"
        redirect_to balance_user_path and return
      end

      # Check whether the account has been closed or not
      if @account.existence == false
        flash[:error] = "The account is closed, please input another existed account"
        redirect_to balance_user_path and return
      end

    @account.update_attributes(:is_threshold => true, :threshold => params[:threshold])
    flash[:success] = "Threshold Setting completed"
    flash[:notice] = "Your will get an alert when your balance of account with ID: " +
                      params[:acct_ID] + " is lower than " + params[:threshold]

    redirect_to balance_user_path
  end

  def set_dr
    @user = User.find(params[:id])

    # Check whether the account exists in the database or not
      begin
        @account = Account.find(params[:acct_ID])
      rescue 
        flash[:error] = "Please input the correct account ID referring to the \"Your Accounts\" above"
        redirect_to balance_user_path and return     
      end
      # If the customer is not inputting the correct account ID
      if @account.user_id != @user.id
        flash[:error] = "Please input the correct account ID referring to the \"Your Accounts\" above"
        redirect_to balance_user_path and return
      end

      # Check whether the account has been closed or not
      if @account.existence == false
        flash[:error] = "The account is closed, please input another existed account"
        redirect_to balance_user_path and return
      end

      # Find the original default_receiving account and set it not to be default_receiving
      if @user.default_receiving_ID == -1
      else
        @original_account = Account.find(@user.default_receiving_ID)
        if @original_account.id == @account.id
          flash[:error] = "This account is already the default_receiving account"
          redirect_to balance_user_path and return
        end
        @original_account.update_attribute(:is_default_receiving,false)
      end

      # Set the default receving attribute to be true
      @account.update_attribute(:is_default_receiving, true)
      @user.update_attribute(:default_receiving_ID, @account.id)

      flash[:success] = "Default receving account setting completed"
      flash[:notice] = "Now your default receving account is the account with ID: " + params[:acct_ID]
      redirect_to balance_user_path
  end

  def open_new_account
    @user = User.find(params[:id])
    @new_account = Account.new

    # Check whether the customer wants this account to receive transfer or not
    @enable = false
    if params[:YesOrNo] == "Yes"
      @enable = true
    elsif params[:YesOrNo] == "No"
      @enable = false
    end

    if params[:AccountType] == "Checking"
      @acct_type = true
    elsif params[:AccountType] == "Saving"
      @acct_type = false
    end

    @new_account.update_attributes(:user_id => @user.id, :acct_type => @acct_type,
                                   :threshold => params[:threshold], :is_threshold => true, 
                                   :is_receiving => @enable, :balance => 0)
    flash[:success] = "A new account is opened."
    redirect_to balance_user_path
  end

  def close_old_account
    @user = User.find(params[:id])

        # Check whether the account exists in the database or not
      begin
        @account = Account.find(params[:old_acct_ID])
      rescue 
        flash[:error] = "Please input the correct account ID referring to the \"Your Accounts\" above"
        redirect_to balance_user_path and return     
      end
      # If the customer is not inputting the correct account ID
      if @account.user_id != @user.id
        flash[:error] = "Please input the correct account ID referring to the \"Your Accounts\" above"
        redirect_to balance_user_path and return
      end
      
      if @account.existence == false
        flash[:error] = "The account has already been closed, you cannot closed it again"
        redirect_to balance_user_path and return
      end

      @account.update_attribute(:existence , false)
      # Also set it not to be the default receiving account if it is the default_receiving account
      if @account.is_default_receiving == true
        @account.update_attribute(:is_default_receiving, false)
        @user.update_attribute(:default_receiving_ID, -1)
        flash[:notice] = "You just closed your default receiving account, please set another account
                          to be the default receving account in order to receive transfer fund from
                          other customer"
      end
      flash[:success] = "Account with ID:" + params[:old_acct_ID] + " is closed"
      redirect_to balance_user_path
  end

  def apply_ip
    Account.all.each do |account|
      next if account.existence == false
      @history = History.new
      @oldBalance = account.balance
      @newBalance = 0
      #If it is a checking account
      if account.acct_type == true && account.balance >= 1000
        if account.balance >= 3000
          @newBalance = account.balance * (1 + 0.03)
          account.update_attribute(:balance,@newBalance)
        elsif account.balance >= 2000
          @newBalance = account.balance * (1 + 0.02)
          account.update_attribute(:balance,@newBalance)
        elsif account.balance >= 1000
          @newBalance = account.balance * (1 + 0.01)
          account.update_attribute(:balance,@newBalance)
        end
      @history.update_attributes(:acct_id => account.id, :balance => account.balance,
                                :cd => 3, :amount => account.balance - @oldBalance, :cs => true)
      #If it is a saving account
      else account.acct_type == false && account.balance >= 1000
        if account.balance >= 3000
          @newBalance = account.balance * (1 + 0.04)
          account.update_attribute(:balance,@newBalance)
        elsif account.balance >= 2000
          @newBalance = account.balance * (1 + 0.03)
          account.update_attribute(:balance,@newBalance)
        elsif account.balance >= 1000
          @newBalance = account.balance * (1 + 0.02)
          account.update_attribute(:balance,@newBalance)
        end
      @history.update_attributes(:acct_id => account.id, :balance => account.balance,
                                :cd => 3, :amount => account.balance - @oldBalance, :cs => false)
      end

      #No matter checking or saving
      if account.balance < 100
        @newBalance = account.balance - 25
        account.update_attribute(:balance,@newBalance)
        @history.update_attributes(:acct_id => account.id, :balance => account.balance,
                                   :cd => 4, :amount => 25, :cs => account.acct_type)
      end
    end

    flash[:success] = "Interest and penalty have been applied to all the accounts"
    redirect_to transfer_user_path
  end

  def edit
    @user = User.find(params[:id])   # Not necessary because of the method correct_user
  end

 def update
    @user = User.find(params[:id])
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

  # def destroy
  #   User.find(params[:id]).destroy
  #   flash[:success] = "Account Closed."
  #   redirect_to users_url
  # end

  def close_account
    @user = User.find(params[:id])
    @user.update_attribute(:existence, false)
    flash[:success] = "Account Closed."
    redirect_to users_url
  end

  
  def balance
    @user = User.find(params[:id])
    @accounts = Array.new
   
    @histories = Array.new      # Array of strings representing transaction histories

    # Retrive all the accounts that this user has and put them into an array 
    # for later use in the balance view.
    @all_accounts_strings = Array.new

    Account.all.each do |account|
      if account.user_id == @user.id 
        next if account.existence == false
        @accounts.push(account)

        # Formualte the string for the account 
        @account_strings = Array.new
        if account.acct_type == true
          @account_strings.push('Checking'.html_safe)
        else
          @account_strings.push('Saving'.html_safe)
        end

        @account_strings.push(account.id.to_s())
        @account_strings.push(account.balance.to_s())

        @all_accounts_strings.push(@account_strings)
      end  
    end

    # Retrive all the transaction histories of this user's account
    # and formulate the corresponding string for the balance view page 
    # to print it out
    History.all.each do |history|
      @accounts.each do |account|
        if account.id == history.acct_id
          @history_strings = Array.new

          @history_strings.push(history.created_at.to_s().html_safe)  # transaction time
          @history_strings.push(history.amount.to_s().html_safe)      # transaction amount
          @history_strings.push(history.balance.to_s().html_safe)     # balance of account
          @history_strings.push(history.acct_id.to_s())               # account ID

          # Check for whether it is a checking account or saving account
          # It is a checking account
          if history.cs == true
            # It is a credit action
            if history.cd == 1            
              @history_strings.push('Credit'.html_safe)
              @history_strings.push('Checking'.html_safe)
            # It is a debit action
            elsif history.cd == 2
              @history_strings.push('Debit'.html_safe)
              @history_strings.push('Checking'.html_safe)   
            # It is a interest
            elsif history.cd == 3
              @history_strings.push('Interest'.html_safe)
              @history_strings.push('Checking'.html_safe)  
            # It is a penalty
            elsif history.cd == 4
              @history_strings.push('Penalty'.html_safe)
              @history_strings.push('Checking'.html_safe)      
            end

            
          # It is a saving account
          elsif history.cs == false
            # It is a credit action
            if history.cd == 1
              @history_strings.push('Credit'.html_safe)
              @history_strings.push('Saving'.html_safe)
            # It is a debit action
            elsif history.cd == 2
              @history_strings.push('Debit'.html_safe)
              @history_strings.push('Saving'.html_safe)  
            # It is a interest
            elsif history.cd == 3
              @history_strings.push('Interest'.html_safe)
              @history_strings.push('Checking'.html_safe)  
            # It is a penalty
            elsif history.cd == 4
              @history_strings.push('Penalty'.html_safe)
              @history_strings.push('Checking'.html_safe)           
            end

          end
        @histories.push(@history_strings)
        end
      end
    end
  end

  # def balance
  #   @user = User.find(params[:id])
  #   @histories = Array.new      # Array of strings representing transaction histories
  #   History.all.each do |history|
  #     if history.user_id == @user.id
  #       if history.cd == 1
  #         @the_string = history.created_at.to_s().html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
  #         'Credit'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.amount.to_s().html_safe + 
  #         '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
  #         'CheckingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.balance.to_s() +
  #         '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe +
  #         'SavingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.sbalance.to_s()
  #       elsif history.cd == 2
  #         @the_string = history.created_at.to_s().html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
  #         'Debit'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.amount.to_s().html_safe + 
  #         '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
  #         'CheckingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.balance.to_s() +
  #         '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe +
  #         'SavingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.sbalance.to_s()
  #       elsif history.cd == 3
  #         @the_string = history.created_at.to_s().html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
  #         'Trans C --> S'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.amount.to_s().html_safe + 
  #         '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
  #         'CheckingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.balance.to_s() +
  #         '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe +
  #         'SavingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.sbalance.to_s()
  #       elsif history.cd == 4
  #         @the_string = history.created_at.to_s().html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
  #         'Trans S --> C'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.amount.to_s().html_safe + 
  #         '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + 
  #         'CheckingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.balance.to_s() +
  #         '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe +
  #         'SavingBalance'.html_safe + '&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.html_safe + history.sbalance.to_s()
  #       end

  #       @histories.push(@the_string)
  #     end
  #    end
  # end

  def process_cd
    @user = User.find(params[:id])
    @acct_id = params[:acct_id]
    @amount = params[:amount]
    @history = History.new
    @cd = 0
    @cs = false

    # Check whether the account exists in the database or not
    begin
      @account = Account.find(@acct_id)
    rescue 
      flash[:error] = "Please input the correct account ID referring to the customer's account list above"
      redirect_to balance_user_path and return     
    end
    # If the customer is not inputting the correct account ID
    if @account.user_id != @user.id
      flash[:error] = "Please input the correct account ID referring to the customer's account list above"
       redirect_to balance_user_path and return
    end

    # Check whether the account has been closed or not
    if @account.existence == false
      flash[:error] = "The account is closed, please input another existed account"
      redirect_to balance_user_path and return
    end

    # Check what type of account is it
    if @account.acct_type == true
      @cs = true
    else
      @cs = false
    end

    # Check whether the account belongs to this user
    if @account.user_id != @user.id
      flash[:error] = "No account of this user matches this account ID"
      flash[:notice] = "Please refer to the account list and input the correct account ID"
      redirect_to balance_user_path(@user) and return 
    end

    # If it is a credit action
    if params[:credit]
      @cd = 1
      @balance = @account.balance + @amount.to_f
    # If it is a debit action
    elsif params[:debit]
      @cd = 2
      @balance = @account.balance - @amount.to_f
      # Have to check whether there is enough money in the account
      # If there is not enought money, give warning and return to transfer page
      if @balance < 0
        flash[:error] = "Transaction is failed"
        flash[:notice] = "You cannot withdrawl more than what is now in your account"
        redirect_to balance_user_path(@user) and return
      end
    end

    if @account.update_attribute(:balance, @balance)
      flash[:success] = "Transaction is successful"

      # Check for threshold
      if @account.balance < @account.threshold
        flash[:notice] = "The balance of your account with ID:" + @account.id + " is lower than " +
                         @account.threshold
      end

      @history.update_attributes(:acct_id => @account.id, :balance => @balance,
                                :cd => @cd, :amount => @amount, :cs => @cs)
      redirect_to balance_user_path(@user) 
    else
      render 'balance'
    end
  end

  # def process_cd
  #   @user = User.find(params[:id])
  #   @history = History.new
  #   @amount = params[:amount]  # The amount of money that is credited or debited to the account
  #   @cd = 0     # The flag to determine whether it is an action of credit or debit
  #   if params[:credit]
  #     @cd = 1
  #     @balance = @user.balance + @amount.to_f
  #   elsif params[:debit]
  #     @cd = 2
  #     @balance = @user.balance - @amount.to_f
  #     if @balance < 0
  #       flash[:error] = "Transaction is failed"
  #       flash[:notice] = "You cannot withdrawl more than what is now in your account"
  #       redirect_to balance_user_path(@user) and return
  #     end
  #   end

  #   if @user.update_attribute(:balance, @balance)
  #     flash[:success] = "Transaction is successful"

  #     @history.update_attributes(:user_id => @user.id, :balance => @user.balance,
  #                                :sbalance => @user.sbalance, :cd => @cd, :amount => @amount)

  #     redirect_to balance_user_path(@user)
  #   else
  #     render 'balance'
  #   end
  # end

  def transfer
    @users = Array.new
    User.all.each do |user|
      next if user.existence == false || user.admin == true
      @users.push(user)
    end

    # Retrive all the accounts that this user has and put them into an array 
    # for later use in the transfer view.
    @user = User.find(params[:id])
    @all_accounts_strings = Array.new

    Account.all.each do |account|
      if account.user_id == @user.id 
        next if account.existence == false

        # Formualte the string for the account 
        @account_strings = Array.new
        if account.acct_type == true
          @account_strings.push('Checking'.html_safe)
        else
          @account_strings.push('Saving'.html_safe)
        end

        @account_strings.push(account.id.to_s())
        @account_strings.push(account.balance.to_s())

        @all_accounts_strings.push(@account_strings)
      end  
    end

  end

  def process_transfer
    if is_admin?

      # Find the two customers by their email
      if @sUser = User.find_by_email(params[:source_email])
      else
        flash[:error] = "Cannot find source user, please make sure the email is correct"
        redirect_to transfer_user_path and return
      end

      if @dUser = User.find_by_email(params[:dest_email])
      else
        flash[:error] = "Cannot find destination user, please make sure the email is correct"
        redirect_to transfer_user_path and return
      end

      # Retrive all the accounts of source customer and destination customer
      # and formulating corresponding string for printing the accounts information
      # on the process_transfer page
      @sAccounts = Array.new
      @all_sAccounts_strings = Array.new
      @dAccounts = Array.new
      @all_dAccounts_strings = Array.new

      Account.all.each do |account|
        if account.user_id == @sUser.id
          @sAccounts.push(account)

          # Formualte the string for the source account 
          @sAccount_strings = Array.new
          if account.acct_type == true
            @sAccount_strings.push('Checking'.html_safe)
          else
            @sAccount_strings.push('Saving'.html_safe)
          end

          @sAccount_strings.push(account.id.to_s())
          @sAccount_strings.push(account.balance.to_s())

          @all_sAccounts_strings.push(@sAccount_strings)

        elsif account.user_id == @dUser.id
          @dAccounts.push(account)

          # Formualte the string for the destination account 
          @dAccount_strings = Array.new
          if account.acct_type == true
            @dAccount_strings.push('Checking'.html_safe)
          else
            @dAccount_strings.push('Saving'.html_safe)
          end

          @dAccount_strings.push(account.id.to_s())
          @dAccount_strings.push(account.balance.to_s())

          @all_dAccounts_strings.push(@dAccount_strings)

        end
      end

    else
      @user = User.find(params[:id])
      # Check whether it is an internal or outside transfer
      if params[:internal]
        @amount = params[:i_amount].to_f
        # Check whether the account exists in the database or not
        begin
          @sAccount = Account.find(params[:source_account_id])
          @dAccount = Account.find(params[:dest_account_id])
        rescue 
          flash[:error] = "Please input the correct account ID referring to the \"My Accounts\" above"
          redirect_to transfer_user_path and return     
        end
        # If the customer is not inputting the correct account ID
        if @sAccount.user_id != @user.id || @dAccount.user_id != @user.id
          flash[:error] = "Please input the correct account ID referring to the \"My Accounts\" above"
          redirect_to transfer_user_path and return
        end
        # Check whether there are blanks
        if @amount == nil || @amount <= 0
          flash[:error] = "Transfer Amount cannot be blank or non-positive"
          redirect_to transfer_user_path and return
        end

        # Check whether the account has been closed or not
        if @sAccount.existence == false || @dAccount.existence == false
          flash[:error] = "one of the accounts is closed, please input another existed account"
          redirect_to transfer_user_path and return
        end

        # Check whether the destination account is eligible for receiving or not
        if @dAccount.is_receiving == false
          flash[:error] = "The destination account is not eligible for receiving transfer,
                           please choose another account"
          redirect_to transfer_user_path and return 
        end

        # Check whether the source account has enough money or not
        if @sAccount.balance - @amount < 0
          flash[:error] = "The source account does not have enough money to transfer out"
          redirect_to transfer_user_path and return
        end

        # Transfer the money
        @newSBalance = @sAccount.balance - @amount
        @newDBalance = @dAccount.balance + @amount

        @sAccount.update_attribute(:balance, @newSBalance)
        @dAccount.update_attribute(:balance, @newDBalance)

        # Generate transaction history
        @sHistory = History.new
        @dHistory = History.new

        @sHistory.update_attributes(:acct_id => @sAccount.id, :balance => @sAccount.balance, :cd => 2,
                                    :amount => @amount, :cs => @sAccount.acct_type)

        @dHistory.update_attributes(:acct_id => @dAccount.id, :balance => @dAccount.balance, :cd => 1,
                                    :amount => @amount, :cs => @dAccount.acct_type)
        flash[:success] = "Internal transfer is completed"
        redirect_to transfer_user_path
      elsif params[:outside]
        @amount = params[:amount].to_f

        @recipient = User.find_by_email(params[:recipient_email])
        @recipient_confirm = User.find_by_name(params[:recipient_name])

        # Check whether there are blanks
        if @recipient == nil || @recipient_confirm == nil 
          flash[:error] = "Please fill out both the name and email correctly"
          redirect_to transfer_user_path and return
        end

        if @amount == nil || @amount <= 0
          flash[:error] = "Transfer Amount cannot be blank or non-positive"
          redirect_to transfer_user_path and return
        end

        # Check whether the name and emails match or not
        if @recipient.id != @recipient_confirm.id 
          flash[:error] = "The name and email do not match, please confirm"
          redirect_to transfer_user_path and return
        end

        # Check whether the account exists in the database or not
        begin
          @account = Account.find(params[:acct_ID])
        rescue
          flash[:error] = "Please input the correct account ID refer to \"My accounts\" aboveeee"
          redirect_to transfer_user_path and return
        end

        # Check whether the account belongs to this user or not
        if @account.user_id != @user.id
          flash[:error] = "Please input the correct account ID refer to \"My accounts\" abovesss"
          redirect_to transfer_user_path and return
        end

        # Check whether the name or email is this user
        if @account.user_id == @recipient.id
          flash[:error] = "You should input other customer's name or email here; if you want to do 
                           internal transfer, please use the internal transfer tool above"
          redirect_to transfer_user_path and return
        end

        # Check whether there is enough money or not
        if @account.balance - @amount < 0
          flash[:error] = "You don't have enough money in this account, please choose another one"
          redirect_to transfer_user_path and return
        end

        # Get recipient's default receiving account
        if @recipient.default_receiving_ID == -1
          flash[:error] = "The recipient does not have an account that is eligible for receving 
                           transfer fund from other customer"
          redirect_to transfer_user_path and return
        end
        @rAccount = Account.find(@recipient.default_receiving_ID)

        # Transfer the money
        @newSBalance = @account.balance - @amount
        @newRBalance = @rAccount.balance + @amount

        @account.update_attribute(:balance, @newSBalance)
        @rAccount.update_attribute(:balance, @newRBalance)

        # Generate transaction history
        @sHistory = History.new
        @rHistory = History.new

        @sHistory.update_attributes(:acct_id => @account.id, :balance => @account.balance, :cd => 2,
                                    :amount => @amount, :cs => @account.acct_type)

        @rHistory.update_attributes(:acct_id => @rAccount.id, :balance => @rAccount.balance, :cd => 1,
                                    :amount => @amount, :cs => @rAccount.acct_type)
        flash[:success] = "Outside transfer is completed"
        redirect_to transfer_user_path
      end
          
    end
  end

  def do_transfer
    if is_admin?
      # Get the source and destination account 
      # and the amount of transfer from the form submitted
      # from process_transfer page
      @sAccount = Account.find(params[:sAccount_id])
      @dAccount = Account.find(params[:dAccount_id])

      # Check for the account's eligibility for receiving money
      if @dAccount.is_receiving == false
        flash[:error] = "The Destination Account is not eligible to receive transfer"
        redirect_to transfer_user_path and return
      end

      @sHistory = History.new
      @dHistory = History.new

      # Check whether they are from the same user
      if @sAccount.user_id == @dAccount.user_id
        flash[:error] = "Bank teller cannot transfer money between the same user's accounts"
        redirect_to transfer_user_path and return 
      end

      # Check whether the bank teller input the correct amount of money to transfer
      if !(@amount = params[:amount].to_f) || @amount <= 0
        flash[:error] = "Please input the correct amount of money you want to transfer"
        redirect_to transfer_user_path and return 
      end

      # Check whether there is enough money in the source account
      if @sAccount.balance - @amount < 0
        flash[:error] = "There is not enough money in the source account"
        redirect_to transfer_user_path and return
      else
        @newSBalance = @sAccount.balance - @amount
        @newDBalance = @dAccount.balance + @amount
        @sourceCS = @sAccount.acct_type
        @destCS = @dAccount.acct_type
        @sourceCD = 2
        @destCD = 1

        @sAccount.update_attribute(:balance, @newSBalance)
        @dAccount.update_attribute(:balance, @newDBalance)

        @sHistory.update_attributes(:acct_id => @sAccount.id, :balance => @newSBalance,
                                   :cd => @sourceCD, :amount => @amount, :cs => @sourceCS)    
        @dHistory.update_attributes(:acct_id => @dAccount.id, :balance => @newDBalance,
                                   :cd => @destCD, :amount => @amount, :cs => @destCS)  

        flash[:success] = "Transfer is completed"

        redirect_to transfer_user_path

      end      
    else
      flash[:error] = "Only bank teller can do this"
      redirect_to transfer_user_path
    end

  end

  # def process_transfer
  #   if is_admin?
  #     # For transaction history
  #     @sHistory = History.new
  #     @dHistory = History.new

  #     # Get the email from view
  #     @sEmail = params[:source_email]
  #     @dEmail = params[:dest_email]

  #     # Find the two customers by their email
  #     if @sUser = User.find_by_email(@sEmail)
  #     else
  #       flash[:error] = "Cannot find source user, please make sure the email is correct"
  #       redirect_to transfer_user_path and return
  #     end

  #     if @dUser = User.find_by_email(@dEmail)
  #     else
  #       flash[:error] = "Cannot find destination user, please make sure the email is correct"
  #       redirect_to transfer_user_path and return
  #     end

  #     # Get the transfer amount from view
  #     @amount = params[:amount].to_f

  #     # Check for balance for the source account
  #     if(@amount > @sUser.balance)
  #       flash[:error] = "Cannot transfer because the source account does not have enough balance"
  #       redirect_to transfer_user_path and return
  #     else
  #       @newSBalance = @sUser.balance - @amount
  #       @newDBalance = @dUser.balance + @amount

  #       @sUser.update_attribute(:balance, @newSBalance)
  #       @dUser.update_attribute(:balance, @newDBalance)
  #       flash[:success] = "Transfer is completed"

  #       @sHistory.update_attributes(:user_id => @sUser.id, :balance => @sUser.balance,
  #                                    :cd => 2, :amount => @amount)

  #       @dHistory.update_attributes(:user_id => @dUser.id, :balance => @dUser.balance,
  #                                    :cd => 1, :amount => @amount)

  #       redirect_to transfer_user_path
  #     end
  #   else
  #       @history = History.new

  #       @amount = params[:amount].to_f
  #       @customer = User.find(params[:id])
  #       @cBalance = @customer.balance
  #       @sBalance = @customer.sbalance

  #       # Check whether it is from checking to saving
  #       # or from saving to checking
  #       if params[:cToS]
  #         if (@amount > @cBalance)
  #           flash[:error] = "Checking account does not have enough balance"
  #           redirect_to transfer_user_path and return
  #         else
  #           @cBalance = @customer.balance - @amount
  #           @sBalance = @customer.sbalance + @amount
  #           @customer.update_attributes(:balance => @cBalance, :sbalance => @sBalance)
  #           flash[:success] = "Transfer is completed"

  #           @history.update_attributes(:user_id => @customer.id, :balance => @customer.balance,
  #                   :sbalance => @customer.sbalance, :cd => 3, :amount => @amount)

  #           redirect_to transfer_user_path and return
  #         end
  #       elsif params[:sToC]
  #         if (@amount > @sBalance)
  #           flash[:error] = "Saving account does not have enough balance"
  #           redirect_to transfer_user_path and return
  #         else
  #           @sBalance = @customer.sbalance - @amount
  #           @cBalance = @customer.balance + @amount
  #           @customer.update_attributes(:balance => @cBalance, :sbalance => @sBalance)
  #           flash[:success] = "Transfer is completed"

  #           @history.update_attributes(:user_id => @customer.id, :balance => @customer.balance,
  #                   :sbalance => @customer.sbalance, :cd => 4, :amount => @amount)

  #           redirect_to transfer_user_path and return
  #         end
  #       end  
  #   end
  # end

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
