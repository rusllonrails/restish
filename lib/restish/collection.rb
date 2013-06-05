module Restish
  class Collection < Array
    
    def meta_params(meta)
      @next_url = meta["next_url"]
      @prev_url = meta["prev_url"]
      @count_all = meta["count"]
      self
    end
    
    def next_url
      @next_url
    end

    def prev_url
      @prev_url
    end
    
    def count_all
      @count_all
    end
    
    def next_page_url_params
      return unless @next_url
      URI(@next_url).query      
    end
    
  end
end
