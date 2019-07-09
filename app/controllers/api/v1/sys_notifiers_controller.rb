class Api::V1::SysNotifiersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user

  def index
    page = params[:page].blank? ? 1 : params[:page].to_i
    datas = []
    @devices = Device.joins(:user_devices).includes(:sys_notifiers => :notifier_detail).where(:status_id => DeviceStatus::BINDED, :user_devices => { user_id: @user.id, ownership: UserDevice::OWNERSHIP[:super_admin], visible: true }).reload.page(page).per(5)
    @devices.each do |dv|
      details = []
      dv.sys_notifiers.each do |sys|
        if sys.notifier_type==1
          details << { type: sys.notifier_type, disabled: sys.disabled, mobile: sys.notifier_detail.mobile, content: sys.notifier_detail.content }
        else
          details << { type: sys.notifier_type, disabled: sys.disabled, mobile: "", content: "" }
        end
      end
      datas << { id: dv.id, name: dv.alias, details: details }
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, total_pages: @devices.total_pages, current_page: page, total_count: @devices.total_count }
      end
    end
  end

  def show
    @device = Device.includes(:sys_notifiers => :notifier_detail).where(:id => params[:device_id], :status_id => DeviceStatus::BINDED).first
    details = []
    @device.sys_notifiers.each do |sys|
      if sys.notifier_type==1
        details << { type: sys.notifier_type, disabled: sys.disabled, mobile: sys.notifier_detail.mobile, content: sys.notifier_detail.content }
      else
        details << { type: sys.notifier_type, disabled: sys.disabled, mobile: "", content: "" }
      end
    end
    datas << { id: @device.id, name: @device.alias, details: details }
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas }
      end
    end
  end

  def create
    notifier = SysNotifier.where(:author_id => @user.id, :device_id => params[:device_id], :notifier_type => params[:type]).first
    respond_to do |format|
      format.json do
        if notifier
          notifier.update_attribute(:disabled, params[:switch_status])
        else
          if params[:type].to_i == SysNotifier::TYPE_OPEN_WARN
            detail = NotifierDetail.new(:mobile => params[:mobile], :content => params[:content])
            notifier = SysNotifier.create(:author_id => @user.id, :device_id => params[:device_id], :notifier_detail => detail, :notifier_type => params[:type].to_i, :disabled => params[:switch_status])
          else
            notifier = SysNotifier.create(:author_id => @user.id, :device_id => params[:device_id], :notifier_type => params[:type].to_i, :disabled => params[:switch_status])
          end
        end
        if params[:type].to_i == SysNotifier::TYPE_OPEN_WARN
          detail = NotifierDetail.where(:sys_notifier_id => notifier.id).first
          detail.update_attributes({:mobile => params[:mobile], :content => params[:content]}) if detail
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