# Copyright 2015, Google, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START index]
class ProductsController < ApplicationController

  protect_from_forgery except: :autosearch

  PER_PAGE = 10

  def index
    @products, @cursor = Product.query limit: PER_PAGE, cursor: params[:cursor]
  end
# [END index]

  def new
    @product = Product.new
  end

# [START show]
  def show
    @product = Product.find params[:id]
  end
# [END show]

  def edit
    @product = Product.find params[:id]
  end

# [START update]
  def update
    @product = Product.find params[:id]

    if @product.update product_params
      flash[:success] = "Updated Product"
      redirect_to product_path(@product)
    else
      render :edit
    end
  end
# [END update]

# [START destroy]
  def destroy
    @product = Product.find params[:id]
    @product.destroy
    redirect_to products_path
  end
# [END destroy]

  before_filter :convert_published_on_to_date

# [START create]
  def create
    @product = Product.new product_params

    if @product.save
      flash[:success] = "Added Product"
      redirect_to product_path(@product)
    else
      render :new
    end
  end

  def autosearch

    # Using client demo UI from:
    # https://github.com/pawelczak/EasyAutocomplete/tree/master/demo

    @terms = Product.autosearch(params["phrase"])
    render :json => @terms, :callback => params['callback']
  end

  def health
    render :nothing => true, :status => 200, :content_type => 'text/html'

  end

  private

  def product_params
    params.require(:product).permit(:title, :author, :published_on, :description)
  end
# [END create]

  def convert_published_on_to_date
    if params[:product] && params[:product][:published_on].present?
      params[:product][:published_on] = Time.parse params[:product][:published_on]
    end
  end

end
