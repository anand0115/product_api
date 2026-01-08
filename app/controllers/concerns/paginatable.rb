module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 100

  private

  def page_number
    [params[:page].to_i, DEFAULT_PAGE].max
  end

  def per_page
    per = params[:per_page].to_i
    return DEFAULT_PER_PAGE if per <= 0
    [per, MAX_PER_PAGE].min
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      per_page: collection.limit_value,
      total_count: collection.total_count,
      total_pages: collection.total_pages,
      next_page: collection.next_page,
      prev_page: collection.prev_page
    }
  end

  def paginate(collection)
    collection.page(page_number).per(per_page)
  end
end
