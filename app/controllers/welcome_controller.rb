class WelcomeController < ApplicationController
  def index
  end



  ABOUT_PAGES.keys.each do |p|

    define_method p do
      
      render "page"
    end

  end
end
