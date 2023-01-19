class MessagesController < ApplicationController
  include CableReady::Broadcaster

  before_action :authenticate_user! #, unless: :json_request?

  def index
    @channel = Channel.find params[:channel_id]
    @stream = @channel.stream
    @messages = Message.find_all(*@stream.map(&:first))
    @message = Message.new(channel_id: @channel.id)

    respond_to do |format|
      format.html { render :index }
      format.json { render json: {stream: @stream, messages: @messages} }
    end
  end

  def create
    channel = Channel.find(params[:channel_id])
    message_id = channel.add_stream({type: 'message'})
    message = Message.new(
      message: params[:message][:message],
      id: message_id,
      channel_id: params[:channel_id],
      user_id: current_user&.id || params[:message][:user_id]
    )

    respond_to do |format|
      if message.save
        cable_ready["room"].text_content(
          selector: "[data-channel-id='channel-#{channel.id}'] em",
          text: message.message
        ).append(
          selector: "[data-room-id='room-#{channel.id}']",
          position: "afterbegin",
          html: render_to_string(partial: "message", locals: {message: message, stream: [message_id]})
        )
        cable_ready.broadcast
        format.html { redirect_to channel_path(channel.id) }
        format.js { render js: 'document.getElementById("message_message").value = "";' }
        format.json { render json: message, status: :created }
      else
        format.html { redirect_to channel_path(channel.id) }
        format.json { render json: message.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def message_params
      params.require(:message).permit(:message)
    end
end
