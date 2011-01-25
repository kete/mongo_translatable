class TranslationsController < ApplicationController
  # Prevents the following error from showing up, common in Rails engines
  # A copy of ApplicationController has been removed from the module tree but is still active!
  unloadable

  before_filter :set_translatable_key_and_class
  # just being picky about contextual naming for clarity in variable's purpose
  before_filter :get_translatable, :only => [:new, :create]
  before_filter :get_translated, :except => [:new, :create]
  before_filter :get_translation, :except => [:new, :index, :create]

  # GET /translations
  # GET /translations.xml
  def index
    @translations = @translated.translations

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @translations }
    end
  end

  # GET /translations/1
  # GET /translations/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/new
  # GET /translations/new.xml
  def new
    @translation = @translatable.translate(:locale => (params[:to_locale] || I18n.locale.to_s))

    respond_to do |format|
      format.html # new.html.erb
      format.js { render :layout => false } # needs to come after html for IE to work
      format.xml  { render :xml => @translation }
    end
  end

  # GET /translations/1/edit
  def edit
    @translation = @translated.translation_for(params[:id]) || @translatable_class::Translation.find(params[:id])
  end

  # POST /translations
  # POST /translations.xml
  def create
    translation_params = params[:translation] || params[@translatable_params_name + '_translation']
    @translation = @translatable.translate(translation_params)

    respond_to do |format|
      if @translation.save
        flash[:notice] = t('translations.controllers.created')
        # we redirect to translated object in the new translated version
        # assumes controller name is tableized version of class
        format.html { redirect_to url_for_translated }
        # TODO: adjust :location accordingly for being a nested route
        format.xml  { render :xml => @translation, :status => :created, :location => @translation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /translations/1
  # PUT /translations/1.xml
  def update
    respond_to do |format|
      translation_params = params[:translation] || params[@translatable_params_name + '_translation']
      if @translation.update_attributes(translation_params)
        flash[:notice] = t('translations.controllers.updated')
        format.html { redirect_to url_for_translated }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @translation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /translations/1
  # DELETE /translations/1.xml
  def destroy
    return_to = params[:return_to_translated].present? && params[:return_to_translated] ? url_for_translated : { :action =>:index }
    @translation.destroy

    respond_to do |format|
      flash[:notice] = t('translations.controllers.deleted')
      format.html { redirect_to return_to }
      format.xml  { head :ok }
    end
  end

  protected
  # accepts translation.locale or translation.id for lookup
  # translation.locale should be unique within the scope of @translated
  def get_translation
    @translation = @translated.translation_for(params[:id]) || @translatable_class::Translation.find(params[:id])
  end

  %w{translatable translated}.each do |term|
    define_method("get_" + term) do
      value = @translatable_class.find(params[@translatable_key])

      # handle case of editing translation from another locale than original
      if value.locale != value.original_locale &&
          params[:controller] == 'translations' &&
          params[:action] == 'edit'
        
        starting_locale = I18n.locale
      
        I18n.locale = value.original_locale

        value.reload

        I18n.locale = starting_locale
      end

      instance_variable_set("@" + term, value)
    end
  end

  # assuming nested routing, this should return exactly one params key
  # and its matching class
  def set_translatable_key_and_class
    translatable_keys = params.keys.select { |key| key.to_s.include?('_id') }

    translatable_keys.each do |key|
      key = key.to_s
      if key != 'translation_id' && request
        key_singular = key.sub('_id', '')

        # make sure this is found in the request url
        # thus making this a nested route
        # assumes plural version for controller name
        if request.path.split('/').include?(key_singular.pluralize)
          @translatable_class = key_singular.camelize.constantize
          @translatable_key = key.to_sym
          @translatable_params_name = key_singular
          break
        end
      end
    end
  end
end
