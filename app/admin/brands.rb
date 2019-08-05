ActiveAdmin.register Brand do
  permit_params :name, :intro, :tel, {images:[], category_ids:[], product_ids:[]}, :visible

  menu priority: 2, label: proc{ I18n.t("activerecord.models.brand") }

  filter :name
  filter :tel
  filter :categories
  filter :products
  filter :visible

  scope("全部A") { |supplier| supplier.all }
  scope("可见品牌Y") { |supplier| Brand.visible }
  scope("不可见品牌N") { |supplier| supplier.invisible }

  index do
    selectable_column
    id_column
    column :name
    column :tel
    column :categories do |supplier|
      supplier.categories.visible.map(&:title).join('，')
    end
    column :products do |supplier|
      supplier.products.visible.map(&:title).join('，')
    end
    column :visible
    actions
  end

  show do 
    attributes_table do
      row :id
      row :name
      row :intro
      row :tel
      row :categories do |supplier|
        supplier.categories.visible.map(&:title).join('，')
      end
      row :products do |supplier|
        supplier.products.visible.map(&:title).join('，')
      end
      row :images do |supplier|
        ul do
          supplier.images.each do |img|
            span do
              image_tag(img.url(:small))
            end
          end
        end
      end
      row :visible
    end
  end

  form html: { multipart: true } do |f|
    f.semantic_errors

    f.inputs do
      f.input :name
      f.input :intro
      f.input :tel
      f.input :categories, :as => :check_boxes, :collection => Category.visible.pluck(:title, :id)
      f.input :products, :as => :check_boxes, :collection => Product.visible.pluck(:title, :id)
      f.input :images, as: :file, input_html: { multiple: true }, hint: '尺寸不小于100x100'
      f.input :visible
    end
    f.actions
  end

end