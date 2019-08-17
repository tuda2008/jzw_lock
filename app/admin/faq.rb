ActiveAdmin.register Faq do
  permit_params :title, :content, {images:[]}, :visible

  menu priority: 11, label: proc{ I18n.t("activerecord.models.faq") }

  filter :title
  filter :visible

  scope("全部A") { |faq| faq.all }
  scope("可见帮助Y") { |faq| faq.visible }
  scope("不可见帮助N") { |faq| faq.invisible }

  index do
    selectable_column
    id_column
    column :title
    column :visible
    actions
  end

  show do 
    attributes_table do
      row :id
      row :title
      row :content
      row :images do |faq|
        ul do
          faq.images.each do |img|
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
      f.input :content
      f.input :images, as: :file, input_html: { multiple: true }, hint: '尺寸不小于100x100'
      f.input :images, as: :file, input_html: { multiple: true }
      f.input :images, as: :file, input_html: { multiple: true }
      f.input :images, as: :file, input_html: { multiple: true }
      f.input :visible
    end
    f.actions
  end

end