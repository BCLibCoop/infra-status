# status.libraries.coop
# Alex Legler <a3li@gentoo.org>
# AGPLv3

require 'bundler/setup'
require 'sinatra'
require 'sinatra/partial'
require 'redcarpet'
require 'rss'
require 'socket'

require_relative 'lib/notice_store'
require_relative 'lib/service_registry'
require_relative 'lib/helpers'

MY_URL = 'http://status.libraries.coop/'

configure do
  NoticeStore.instance.update!
  ServiceRegistry.instance.update!
  set :partial_template_engine, :erb
  mime_type :atom, 'application/atom+xml'
  set :bind, '0.0.0.0'
end

get '/' do
  erb :index
end

get '/notice/:id' do
  notice = NoticeStore.instance.notice(params[:id])

  if notice.nil?
    status 404
    erb :layout, :layout => false do
      '<h1>No such notice</h1><p>The notice you have requested does not exist or has been removed as it was resolved long ago.</p>'
    end
  else
    @title = notice['title']
    erb :notice, :locals => { :notice => notice }
  end
end

get '/feed.atom' do
  rss = RSS::Maker.make('atom') do |maker|
    maker.channel.author  = 'BC Libraries Coop System Team'
    maker.channel.title   = 'BC Libraries Coop Notices'
    maker.channel.link    = MY_URL
    maker.channel.id      = MY_URL
    maker.channel.updated = Time.now.to_s

    NoticeStore.instance.visible_notices.each do |notice|
      maker.items.new_item do |item|
        item.link = MY_URL + 'notice/' + notice['id']
        item.title = notice['title']
        item.updated = notice['updated_at'].to_s
        item.description = markdown(notice.get_content)
      end
    end
  end

  content_type :atom
  body rss.to_s
end

# Forcibly update the notice store
get '/force_update' do
  NoticeStore.instance.update!
  ServiceRegistry.instance.update!
  redirect '/#ok'
end

