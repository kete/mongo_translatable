# -*- coding: utf-8 -*-
require 'test_helper'

class TranslationsControllerTest < ActionController::TestCase
  context "The translations controller" do 
    setup do
      @item = Factory.create(:item)
    end

    should "get index" do
      get :index, :item_id => 1
      assert_response :success
      assert_not_nil assigns(:translations)
    end

    should "get new" do
      get :new, :item_id => 1
      assert_response :success
    end

    should "create translation" do
      assert_difference('Item::Translation.count') do
        post :create, :translation => { :label => 'une étiquette', :locale => 'fr'}, :item_id => 1
      end

      assert_redirected_to :action => 'show', :id => assigns(:translation).locale, :item_id => 1
    end

    context "when there is an existing translation" do 
      setup do
        @item.translate(:label => 'une étiquette', :locale => 'fr')
        @translation_1 = @item.translations.first
      end

      should "get index with a translation" do
        get :index, :item_id => 1
        assert assigns(:translations).size == 1
      end

      should "show translation" do
        get :show, :id => @translation_1.locale, :item_id => 1
        assert_response :success
      end

      should "get edit" do
        get :edit, :id => @translation_1.locale, :item_id => 1
        assert_response :success
      end

      should "update translation" do
        put :update, :id => @translation_1.locale, :translation => { :label => "oui oui" }, :item_id => 1
        assert_redirected_to :action => 'show', :id => assigns(:translation).locale, :item_id => 1
      end

      should "destroy translation" do
        assert_difference('Item::Translation.count', -1) do
          delete :destroy, :id => @translation_1.locale, :item_id => 1
        end

        assert_redirected_to :action => :index, :item_id => 1
      end
    end
  end

end

