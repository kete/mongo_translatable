module TranslatablesHelper
  def available_in_locales_for(translatable, options = {})
    html = "<ul style='list-style:none; margin:0; padding:0;'>"
    html += "<li style='float:left;'>#{I18n.t('translations.helpers.available_in')}</li>"

    translatable.available_in_these_locales.each_with_index do |locale, index|
      styles = "float: left; padding: 0 5px; #{'border-left: 1px solid #000' unless index == 0}"
      onclick = 'update_translation_box(this); return false' if options[:lightbox]
      html += content_tag(:li, :style => styles) do
        link_to_unless_current(TranslationsHelper::available_locales[locale],
          url_for(:locale => locale, :to_locale => (params[:to_locale] if defined?(params))),
          { :onclick => onclick })
      end
    end

    html += '</ul>'
    html += "<div style='clear:both;'></div>"
    html
  end

  def needed_in_locales_for(translatable, options = {})
    html = "<ul style='list-style:none; margin:0; padding:0;'>"
    html += "<li style='float:left;'>#{I18n.t('translations.helpers.needs_translating_to')}</li>"

    translatable_key = translatable.class.name.tableize.singularize + '_id'
    needed_locales = translatable.needed_in_these_locales
    return unless needed_locales.any?

    needed_locales.each_with_index do |locale, index|
      styles = "float: left; padding: 0 10px; #{'border-left: 1px solid #000' unless index == 0}"
      onclick = 'update_translation_box(this); return false' if options[:lightbox]
      html += content_tag(:li, :style => styles) do
        link_to(TranslationsHelper::available_locales[locale],
                { :action => :new,
                :controller => :translations,
                translatable_key => translatable,
                :to_locale => locale }, { :onclick => onclick })
      end
    end

    html += '</ul>'
    html += "<div style='clear:both;'></div>"
    html
  end

  def translatable_lightbox_js_and_css
    js = javascript_tag("
    function close_open_translation_box() {
      if ($('translate_outer_box')) { $('translate_outer_box').remove(); }
      if ($('translate_inner_box')) { $('translate_inner_box').remove(); }
    }

    function update_translation_box(element) {
      new Ajax.Request(element.href, {
        method: 'get',
        onSuccess: function(transport) {
          var outer_box = Element('div', { 'id': 'translate_outer_box' }).setOpacity(0.8);
          var close_link = '<a href=\\'\\' title=\\'Close\\' onclick=\\'close_open_translation_box(); return false;\\'>#{I18n.t('translations.helpers.close_box')}</a>';
          var close_box = '<div id=\\'translate_close_box\\'>' + close_link + '</div>';
          var inner_box = Element('div', { 'id': 'translate_inner_box' }).update(close_box + transport.responseText);
          close_open_translation_box();
          document.body.appendChild(outer_box);
          document.body.appendChild(inner_box);
        }
      });
    }
    ")

    css = content_tag("style", :type => "text/css") do
      <<-CSS
      #translate_outer_box { position: absolute; top: 0; right: 0; bottom: 0; left: 0; overflow: auto;
                           background-color: #000; }
      #translate_inner_box { position: absolute; top: 10%; right: 20%; left: 20%; width: 60%; background-color: #fff;
                           padding: 20px; -moz-border-radius: 1em; -webkit-border-radius: 1em;  }
      #translate_close_box { float: right; margin-top: -45px; margin-right: -15px; }
      #translate_close_box a { color: #fff; }
      CSS
    end

    js + css
  end

  def google_auto_translatable_js
    @google_auto_translatable_enabled = true
    javascript_include_tag("http://www.google.com/jsapi?format=") +
    javascript_tag("
    google.load('language', '1');
    function getGoogleTranslation(field_id, text, from_language, to_language) {
      google.language.translate(text, from_language, to_language, function(result) {
        if (!result.error) { Form.Element.setValue(field_id, result.translation); }
      });
    }
    ")
  end
end
