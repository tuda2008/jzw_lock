ActiveAdmin.register User do
  
  actions :index, :show

  filter :provider, as: :select, collection: User::PROVIDER_COLLECTION
  filter :nickname
  filter :province
  filter :city
  filter :gender, as: :select, collection: User::GENDER_COLLECTION

  scope("全部A") { |user| user.all }
  scope("男性M") { |user| user.male }
  scope("女性F") { |user| user.female }

  index do
    id_column
    column :provider do |user|
      User::PROVIDER_HASH[user.provider]
    end
    column :nickname
    column :avatar_url do |user|
      image_tag(user.avatar_url, size: "48x48") unless user.avatar_url.blank?
    end
    column :province
    column :city
    column :gender do |user|
      User::GENDER_HASH[user.gender]
    end
    actions
  end

  show do 
    attributes_table do
      row :id
      row :provider do |user|
	      User::PROVIDER_HASH[user.provider]
	    end
      row :nickname
      row :avatar_url do |user|
        image_tag(user.avatar_url) unless user.avatar_url.blank?
      end
      row :province
      row :city
      row :gender do |user|
        User::GENDER_HASH[user.gender]
      end
      row :invitors do |user|
        user.invitors.map(&:name).join(',')
      end
    end
  end
end