ActiveAdmin.register Product do
  permit_params :title, :intro, {images:[], brand_ids:[], category_ids:[]}, :visible

  menu priority: 4, label: proc{ I18n.t("activerecord.models.product") }

  filter :title
  filter :brands 
  filter :categories
  filter :visible

  scope("全部A") { |product| product.all }
  scope("可见产品Y") { |product| product.visible }
  scope("不可见产品N") { |product| product.invisible }

  index do
    selectable_column
    id_column
    column :title
    column :brands do |product|
      product.brands.visible.map(&:name).join('，')
    end
    column :categories do |product|
      product.categories.visible.map(&:title).join('，')
    end
    column :visible
    actions
  end

  show do 
    attributes_table do
      row :id
      row :title
      row :intro
      row :brands do |product|
        product.brands.visible.map(&:name).join('，')
      end
      row :categories do |product|
        product.categories.visible.map(&:title).join('，')
      end
      row :images do |product|
        ul do
          product.images.each do |img|
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
      f.input :title
      f.input :intro
      f.input :brands, :as => :check_boxes, :collection => Brand.visible.pluck(:name, :id)
      f.input :categories, :as => :check_boxes, :collection => Category.visible.pluck(:title, :id)
      f.input :images, as: :file, input_html: { multiple: true }, hint: '尺寸不小于100x100'
      f.input :visible
    end
    f.actions
  end
end