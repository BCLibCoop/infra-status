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

  def services_info(services)
    content = '<div class="list-group">'

    services.each do |service|
      _service_status = service_status(service)
      _status_text = status_text(_service_status)
      _service_info = service_info(service)
      service_name = ServiceRegistry.instance.services[service][:name]
      data_service_name = service_name.gsub('"', "'")
      content << "
        <a class=\"list-group-item has-tooltip notice-link\" href=\"#notices\" title=\"#{_status_text}\"
           data-toggle=\"tooltip\" data-placement=\"top\" data-container=\"body\"
           data-service=\"#{service}\" data-service-name=\"#{data_service_name}\">
        #{_service_info}
        #{service_name}
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
        return '<img src="/icons/status_up.png" alt="The service is up and running." title="The service is up and running." class="pull-right" />'
      when 'down'
        return '<img src="/icons/status_down.png" alt="There are indications the service is down." title="There are indications the service is down." class="pull-right" />'
      when 'warning'
        return '<img src="/icons/status_warning.png" alt="There are issues with the service." title="There are issues with the service." class="pull-right" />'
      when 'maintenance'
        return '<img src="/icons/maintenance.png" alt="The service is undergoing scheduled maintenance." title="The service is undergoing scheduled maintenance." class="pull-right" />'
      else
        return '<img src="/icons/na.png" alt="No data available." title="No data available." class="pull-right" />'
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
        return '<img src="/icons/maintenance.png" alt="Scheduled maintenance" title="Scheduled maintenance" style="vertical-align: text-top;" />'
      when 'outage'
        return '<img src="/icons/outage.png" alt="Unplanned outage" title="Unplanned outage" style="vertical-align: text-top;" />'
      when 'information'
        return '<img src="/icons/information.png" alt="General information" title="General information" style="vertical-align: text-top;" />'
    end
  end

  def date_format(date)
    if date.nil?
      'n/a'
    else
      date.rfc2822
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
