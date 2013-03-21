# -*- coding: utf-8 -*-

require 'sinatra/rocketio'

# $watchers[timeline_id] = [session_id, ...]
$watchers = Hash.new { |h, k| h[k] = Set.new }

# $watchees[session_id] = Set.new
$watchees = Hash.new

class Porotter < Sinatra::Base
  register Sinatra::Namespace
  register Sinatra::RocketIO

  configure :development do
    register Sinatra::Reloader
    also_reload "#{File.dirname(__FILE__)}/*.rb"
    also_reload "#{File.dirname(__FILE__)}/models/*.rb"
  end

  configure do
    io = Sinatra::RocketIO
    io.on :connect do |session, type|
      puts "new client <#{session}> (type:#{type})"
    end

    io.on :disconnect do |session, type|
      puts "delete client <#{session}> (type:#{type})"
      $watchees.delete(session)
    end

    io.on :watch do |data, session, type|
      puts "params: #{data}, <#{session}> type: #{type}"

      begin 
        targets = data["targets"].map { |e| e.to_i }

        # targetsから要素が削除されている場合、
        # $watchers[some]にはsessionが含まれているのに
        # $watchees[session]にはsomeが含まれていないケースが生じるが、
        # その判定はlazyに(通知時に)行う。

        $watchees[session] = Set.new(targets)
        targets.each do |timeline_id|
          $watchers[timeline_id] << session
        end
      rescue => e
        puts e
        puts e.backtrace
      end
    end


    EM.defer do
      Redis.new.subscribe("timeline-watcher") do |on|
        on.message do |channel, message|
          timeline_id, version = JSON.parse(message)
          deleted = []
          $watchers[timeline_id].each do |session|
            if $watchees.member?(session) &&
                $watchees[session].member?(timeline_id)
              puts "send watch message"
              io.push :watch, {:timeline => timeline_id}, {:to => session }
            else
              deleted.push session
            end
          end
          $watchers[timeline_id].subtract(deleted)
          puts "some post detected: #{message}"
        end
      end
    end
  end

  enable :sessions
  set :session_secret, 'porotter secret'
  set :public_folder, "#{File.dirname(__FILE__)}/public"
  
  include WebServerHelper
  def here; ""; end

  before do
    @user = User.attach_if_exist(session['user_id'])
    s = request.path_info.split('/')[1]
    if !@user && s != 'user' && s != 'p' && s != 'static'
      redirect "#{URL_PREFIX}/account/login", 303
    end
  end

  get '/' do
    # erb :mypage
    erb :allpage
  end

  get "/user/all" do
    erb :allpage
  end

  get '/user/*' do |username|
    target = User.store_class.find_by_username(username) or halt 404
    erb :userpage, :locals => { :target => target }
  end

  get '/p/timeline' do
    direction = symbolize(params['direction'], [:upward, :downward]) or halt 403
    comment = symbolize(params['comment'], [:enabled, :disabled]) or halt 403
    render_timeline(Timeline.attach_if_exist(params['timeline'].to_i), direction, comment)
  end

  post '/m/newarticle' do
    @user.add_post(params[:content])
    "OK"
  end

  post '/m/newcomment' do
    post = Post.attach_if_exist(params[:parent].to_i) or halt 403
    @user.add_comment(post, params[:content])
    "OK"
  end

  get '/m/favor' do
    post = Post.attach_if_exist(params[:target].to_i) or halt 403
    @user.toggle_favorite(post)
    redirect local_url('/')
  end

  get %r{/static/(.*)\.css} do |path|
    scss :"#{path}"
  end

  get %r{/static/(.*\.(js|css|png|gif))} do |path, ext|
    send_file File.join(settings.public_folder, path)
  end

  private
  def render_timeline(timeline, direction, comment)
    halt 403 unless timeline
    erb :_timeline, :locals => { :user => @user, :root => timeline, :timeline => timeline, :comment => comment, :direction => direction }
  end

  def symbolize(s, candidates)
    candidates.each do |c|
      return c if c.to_s == s
    end
    return nil
  end

end
