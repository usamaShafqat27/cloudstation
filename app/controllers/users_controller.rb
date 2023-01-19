# frozen_string_literal: true

class UsersController < ApplicationController

  def new
    @user = User.new
  end

  def create
    user = User.new(**user_params)
    user.password = params[:user][:password]

    respond_to do |format|
      if user.try(:save)
        session[:user_id] = user.id
        format.html { redirect_to channels_path, notice: 'Sign up successful' }
        format.json { render :user, status: :created }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    def user_params
      params.require(:user).permit(:firstname, :lastname, :city, :country, :username, :password)
    end
end
