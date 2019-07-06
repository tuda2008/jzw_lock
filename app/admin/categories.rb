ActiveAdmin.register Category do
  permit_params :title, :intro, {images:[], brand_ids:[], product_ids:[]}, :visible

  menu priority: 3, label: proc{ I18n.t("activerecord.models.category") }

  filter :title
  filter :brands 
  filter :products
  filter :visible

  scope("全部A") { |category| category.all }
  scope("可见类别Y") { |category| category.visible }
  scope("不可见类别N") { |category| category.invisible }

  index do
    selectable_column
    id_column
    column :title
    column :brands do |category|
      category.brands.visible.map(&:name).join('，')
    end
    column :products do |category|
      category.products.visible.map(&:title).join('，')
    end
    column :visible
    actions
  end

  show do 
    attributes_table do
      row :id
      row :title
      row :intro
      row :brands do |category|
        category.brands.visible.map(&:name).join('，')
      end
      row :products do |category|
        category.products.visible.map(&:title).join('，')
      end
      row :images do |category|
        ul do
          category.images.each do |img|
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
      f.input :products, :as => :check_boxes, :collection => Product.visible.pluck(:title, :id)
      f.input :images, as: :file, input_html: { multiple: true }, hint: '尺寸不小于100x100'
      f.input :visible
    end
    f.actions
  end

end