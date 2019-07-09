class Api::V1::SysNotifiersController < ApplicationController
	skip_before_action :verify_authenticity_token
  before_action :find_user

  def index
		page = params[:page].blank? ? 1 : params[:page].to_i
    datas = []


  end

  def create
  	notifier = SysNotifier.where(:user_id => @user.id, :device_id => params[:device_id], :notifier_type => params[:type]).first
    respond_to do |format|
      format.json do
        if notifier
					notifier.update_attribute(:disabled, params[:switch])
        else
					notifier = SysNotifier.create(:user_id => @user.id, :device_id => params[:device_id], :notifier_type => params[:type].to_i, :disabled => params[:switch])
        end
        if params[:type].to_i == SysNotifier::TYPE_OPEN_WARN
        	detail = notifier.notifier_detail.where(:mobile => params[:mobile])
        	if detail
        		detail.update_attribute(:content, params[:content])
        	else
        		if notifier.notifier_detail.blank?
        			notifier.notifier_detail.create(:mobile => params[:mobile], :content => params[:content])
        		else
        			notifier.notifier_detail.update_attributes({:mobile => params[:mobile], :content => params[:content]})
        		end
        	end
        end
        render json: { status: 1, message: "ok", data: {} }
      end
    end
  end

  private
    def find_user
      @user = User.find_by(open_id: params[:openid])
    end
end