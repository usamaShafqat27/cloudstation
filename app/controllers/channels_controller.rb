class ChannelsController < ApplicationController
  before_action :authenticate_user! #, unless: :json_request?
  include CableReady::Broadcaster

  def index
    @channel = Channel.new
    @channels = Channel.all
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @channels }
    end
  end

  def create
    @channel = Channel.new(**channel_params, updated_at: Time.now.to_i)

    respond_to do |format|
      if @channel.save
        cable_ready['chat'].append(
          selector: '#channel-list',
          position: 'afterbegin',
          html: render_to_string(partial: 'channel_item', locals: {channel: @channel})
        )
        cable_ready.broadcast

        format.html { redirect_to channels_path, notice: 'Channel Created' }
        format.json { render :user, status: :created }
        format.js { 
          @html = render_to_string(partial: "channel_item", locals: {channel: @channel})
          render :create 
        }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @channel = Channel.find params[:id]
    stream = @channel.stream
    if params[:search]
      @messages = Message.redisearch.search("#{params[:search]} @channel_id:{#{@channel.id}}").map!{|obj| Message.new(**obj)}
    else
      @messages = Message.find_all(*stream.map(&:first))
    end
    @message = Message.new(channel_id: @channel.id)

    respond_to do |format|
      format.html { render :show }
      format.js {
        @html = render_to_string(partial: "channel", locals: {channel: @channel, messages: @messages, message: @message})
        render :show 
      }
      format.json { render json: @channels, status: :created }
    end
  end

  private
    def channel_params
      params.require(:channel).permit(:name)
    end
end
