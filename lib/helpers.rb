helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
    markdown.render(text)
  end

  def get_forced_state(notices)
    notices.each do |notice|
      next unless notice.has_key? 'force_state'

      return notice['force_state']
    end

    nil
  end

  def services_regex(service_regex)
    return ServiceRegistry.instance.services.keys.grep service_regex
  end

  def services_info_regex(service_regex)
    keys = services_regex(service_regex)
    return services_info(keys)
  end

  def services_info(services)
    content = '<div class="list-group">'

    services.each do |service|
      _service_status = service_status(service)
      _status_text = status_text(_service_status)
      _service_info = service_info(service)
      #service_name = ServiceRegistry.instance.services[service][:name]
      service_array = ServiceRegistry.instance.services[service]
      service_name = service_array.nil? ? 'UNKNOWN NAME' : service_array[:name] 
      data_service_name = service_name.gsub('"', "'")
      content << "
        <a class=\"list-group-item has-tooltip notice-link status-#{_service_status}\" href=\"#notices\" title=\"#{_status_text}\"
           data-toggle=\"tooltip\" data-placement=\"top\" data-container=\"body\"
           data-service=\"#{service}\" data-service-name=\"#{data_service_name}\">

        #{service_name}
        #{_service_info}
        </a>"
    end

    content << '</div>'
  end

  def service_status(service)
    return 'na' unless ServiceRegistry.instance.services.has_key? service
    active_notices = NoticeStore.instance.active_notices_for(service)

    unless (forced_state = get_forced_state(active_notices)) == nil
      return forced_state
    else
      case ServiceRegistry.instance.services[service][:status]
        when State::UP
          return 'up'
        when State::WARNING
          return 'warning'
        when State::DOWN
          return 'down'
        else
          return 'na'
      end
    end
  end

  def service_info(service)
    visible_notices = NoticeStore.instance.visible_notices_for(service)

    content = status_icon(service_status(service))
    content << '<span class="badge" style="margin-right: 1em;" title="There are notices (%s) below regarding this service.">%s</span>' % [visible_notices.count, visible_notices.count] if visible_notices.count > 0
    content
  end

  def panel_class(notice)
    if notice['type'] == 'outage'
      'panel-danger'
    elsif notice['type'] == 'information'
      'panel-info'
    elsif notice['type'] == 'maintenance'
      'panel-warning'
    else
      'panel-default'
    end
  end

  def status_icon(status)
    case status.to_s
      when 'up'
        return '<i class="status-icon fa fa-fw fa-check-square" title="The service is up and running"></i>'
      when 'down'
        return '<i class="status-icon fa fa-fw fa-times-circle" title="There are indications the service is down."></i>'
      when 'warning'
        return '<i class="status-icon fa fa-fw fa-warning" title="There are issues with the service."></i>'
      when 'maintenance'
        return '<i class="status-icon fa fa-fw fa-wrench" title="The service is undergoing scheduled maintenance."></i>'
      else
        return '<i class="status-icon fa fa-fw fa-question" title="No data available."></i>'
    end
  end

  def status_text(status)
    case status.to_s
      when 'up'
        return 'The service is up and running.'
      when 'down'
        return 'There are indications the service is down.'
      when 'warning'
        return 'There are issues with the service.'
      when 'maintenance'
        return 'The service is undergoing scheduled maintenance.'
      else
        return 'No data available.'
    end
  end

  def item_icon(type)
    case type.to_s
      when 'maintenance'
        return '<i class="fa fa-wrench"></i>'
      when 'outage'
        return '<i class="glyphicon glyphicon-fire"></i>'
      when 'information'
        return '<i class="fa fa-info-circle"></i>'
    end
  end

  def date_format(date)
    if date.nil?
      'n/a'
    else
      date.httpdate
    end
  end

  def humanize(secs)
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}" unless name == :seconds
      end
    }.compact.reverse.join(' ')
  end
end
