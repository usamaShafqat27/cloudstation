# frozen_string_literal: true

class SessionsController < ApplicationController

  # POST /sessions
  def create
    user = User.find(params[:username])&.try(:authenticate, params[:password])

    respond_to do |format|
      if user
        session[:user_id] = user.id
        format.html { redirect_to channels_path, notice: 'Sign in successful' }
        format.json { render json: {status: :success} }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sessions
  def destroy
    session[:user_id] = nil
    respond_to do |format|
      format.html { redirect_to channels_path, notice: 'Sign in successful' }
      format.json { render json: { status: :logged_out } }
    end
  end
end
