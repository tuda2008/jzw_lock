class Api::V1::SysNotifiersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user

  def index
    page = params[:page].blank? ? 1 : params[:page].to_i
    datas = []
    @devices = Device.joins(:user_devices).where(:status_id => DeviceStatus::BINDED, :user_devices => { user_id: @user.id, ownership: UserDevice::OWNERSHIP[:super_admin], visible: true }).reload.page(page).per(5)
    @devices.each do |dv|
      datas << { id: dv.id, name: dv.alias }
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, total_pages: @devices.total_pages, current_page: page, total_count: @devices.total_count }
      end
    end
  end

  def create
    notifier = SysNotifier.where(:author_id => @user.id, :device_id => params[:device_id], :notifier_type => params[:type]).first
    respond_to do |format|
      format.json do
        if notifier
          notifier.update_attribute(:disabled, params[:switch])
        else
          notifier = SysNotifier.create(:author_id => @user.id, :device_id => params[:device_id], :notifier_type => params[:type].to_i, :disabled => params[:switch])
        end
        if params[:type].to_i == SysNotifier::TYPE_OPEN_WARN
          detail = NotifierDetail.where(:sys_notifier_id => notifier.id, :mobile => params[:mobile]).first
          if detail
            detail.update_attribute(:content, params[:content])
          else
            if detail.blank?
              detail.create(:sys_notifier_id => notifier.id, :mobile => params[:mobile], :content => params[:content])
            else
              detail.update_attributes({:mobile => params[:mobile], :content => params[:content]})
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