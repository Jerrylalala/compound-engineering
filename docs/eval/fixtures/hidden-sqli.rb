# app/controllers/products_controller.rb

class ProductsController < ApplicationController
  before_action :authenticate_user!

  def search
    query = params[:q]

    # 看起来做了防注入处理...
    sanitized_query = sanitize_sql_like(query)

    # 但是！这里用的是原始的 query 而非 sanitized_query
    # sanitized_query 被创建后从未使用
    @products = Product.where("name LIKE '%#{query}%' OR description LIKE '%#{query}%'")

    respond_to do |format|
      format.html
      format.json { render json: @products }
    end
  end

  def advanced_search
    # 这个方法正确使用了参数化查询（对比用）
    @products = Product.where("name LIKE ?", "%#{sanitize_sql_like(params[:q])}%")
  end

  private

  def sanitize_sql_like(string, escape_character = "\\")
    pattern = Regexp.union(escape_character, "%", "_")
    string.gsub(pattern) { |x| [escape_character, x].join }
  end
end
