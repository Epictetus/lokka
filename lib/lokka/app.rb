module Lokka
  class App < Sinatra::Base
    configure do
      enable :method_override, :raise_errors, :static
      set :root, File.expand_path('../../..', __FILE__)
      set :public => Proc.new { File.join(root, 'public') }
      set :views => Proc.new { public }
      set :theme => Proc.new { File.join(public, 'theme') }
      set :config => YAML.load(ERB.new(File.read("#{root}/config.yml")).result(binding))
      set :supported_templates => %w(erb haml erubis)
      set :per_page, 10
      set :admin_per_page, 50
      set :default_locale, 'en'
      set :haml, :ugly => false, :attr_wrapper => '"'
      register Sinatra::Logger
      set :logger_level, :debug
      set :logger_log_file, Proc.new { File.join(root, 'tmp', "#{environment}.log") }

      register Sinatra::R18n
      register Lokka::Before
      register Lokka::Hello
      helpers Sinatra::ContentFor
      helpers Lokka::Helpers

      use Rack::Session::Cookie,
        :expire_after => 60 * 60 * 24 * 12,
        :secret => '_p_y_h_a_'
      use Rack::Flash
      use Rack::Exceptional, ENV['EXCEPTIONAL_API_KEY'] || 'key' if ENV['RACK_ENV'] == 'production'
    end

    configure :production do
      DataMapper.setup(:default, ENV['DATABASE_URL'] || config['development']['dsn'])
    end

    configure :development do
      class Sinatra::Reloader < ::Rack::Reloader
        def safe_load(file, mtime, stderr)
          if File.expand_path(file) == File.expand_path(::Sinatra::Application.app_file)
            ::Sinatra::Application.reset!
            stderr.puts "#{self.class}: reseting routes"
          end
          super
        end
      end
      use Sinatra::Reloader

      DataMapper.setup(:default, config['development']['dsn'])
    end

    get '/admin/' do
      login_required
      render_any :index
    end

    get '/admin/login' do
      render_any :login, :layout => false
    end

    post '/admin/login' do
      @user = User.authenticate(params[:name], params[:password])
      if @user
        session[:user] = @user.id
        if session[:return_to]
          redirect_url = session[:return_to]
          session[:return_to] = false
          redirect redirect_url
        else
          redirect '/admin/'
        end
      else
        render_any :login, :layout => false
      end
    end

    get '/admin/logout' do
      login_required
      session[:user] = nil
      flash[:notice] = 'Logout successful'
      redirect '/admin/login'
    end

    # posts
    get '/admin/posts' do
      login_required
      @posts = Post.all(:order => :created_at.desc).
                    page(params[:page], :per_page => settings.admin_per_page)
      render_any :'posts/index'
    end

    get '/admin/posts/new' do
      login_required
      @post = Post.new(:created_at => DateTime.now)
      @categories = Category.all.map {|c| [c.id, c.title] }.unshift([nil, t.not_select])
      render_any :'posts/new'
    end

    post '/admin/posts' do
      login_required
      @post = Post.new(params['post'])
      @post.user = current_user
      if @post.save
        redirect '/admin/posts'
      else
        @categories = Category.all.map {|c| [c.id, c.title] }.unshift([nil, t.not_select])
        render_any :'posts/new'
      end
    end

    get '/admin/posts/:id/edit' do |id|
      login_required
      @post = Post.get(id)
      @categories = Category.all.map {|c| [c.id, c.title] }.unshift([nil, t.not_select])
      render_any :'posts/edit'
    end

    put '/admin/posts/:id' do |id|
      login_required
      @post = Post.get(id)
      if @post.update(params['post'])
        redirect "/admin/posts/#{id}/edit"
      else
        @categories = Category.all.map {|c| [c.id, c.title] }.unshift([nil, t.not_select])
        render_any :'posts/edit'
      end
    end

    delete '/admin/posts/:id' do |id|
      Post.get(id).destroy
      redirect "/admin/posts"
    end

    # pages
    get '/admin/pages' do
      login_required
      @pages = Page.all(:order => :created_at.desc).
                    page(params[:page], :per_page => settings.admin_per_page)
      render_any :'pages/index'
    end

    get '/admin/pages/new' do
      login_required
      @page = Page.new(:created_at => DateTime.now)
      @categories = Category.all.map {|c| [c.id, c.title] }.unshift([nil, t.not_select])
      render_any :'pages/new'
    end

    post '/admin/pages' do
      login_required
      @page = Page.new(params['page'])
      @page.user = current_user
      if @page.save
        redirect '/admin/pages'
      else
        @categories = Category.all.map {|c| [c.id, c.title] }.unshift([nil, t.not_select])
        render_any :'pages/new'
      end
    end
    
    get '/admin/pages/:id/edit' do |id|
      login_required
      @page = Page.get(id)
      @categories = Category.all.map {|c| [c.id, c.title] }.unshift([nil, t.not_select])
      render_any :'pages/edit'
    end
    
    put '/admin/pages/:id' do |id|
      login_required
      @page = Page.get(id)
      if @page.update(params['page'])
        redirect "/admin/pages/#{id}/edit"
      else
        @categories = Category.all.map {|c| [c.id, c.title] }.unshift([nil, t.not_select])
        render_any :'pages/edit'
      end
    end

    delete '/admin/pages/:id' do |id|
      Page.get(id).destroy
      redirect "/admin/pages"
    end

    # comment
    get '/admin/comments' do
      login_required
      @comments = Comment.all(:order => :created_at.desc).
                    page(params[:page], :per_page => settings.admin_per_page)
      render_any :'comments/index'
    end

    get '/admin/comments/new' do
      login_required
      @comment = Comment.new(:created_at => DateTime.now)
      @entries = Entry.all.map {|e| [e.id, e.title] }.unshift([nil, t.not_select])
      render_any :'comments/new'
    end

    post '/admin/comments' do
      login_required
      @comment = Comment.new(params['comment'])
      if @comment.save
        redirect '/admin/comments'
      else
        @entries = Entry.all.map {|e| [e.id, e.title] }.unshift([nil, t.not_select])
        render_any :'comments/new'
      end
    end
    
    get '/admin/comments/:id/edit' do |id|
      login_required
      @comment = Comment.get(id)
      @entries = Entry.all.map {|e| [e.id, e.title] }.unshift([nil, t.not_select])
      render_any :'comments/edit'
    end
    
    put '/admin/comments/:id' do |id|
      login_required
      @comment = Comment.get(id)
      if @comment.update(params['comment'])
        redirect "/admin/comments/#{id}/edit"
      else
        @entries = Entry.all.map {|e| [e.id, e.title] }.unshift([nil, t.not_select])
        render_any :'comments/edit'
      end
    end

    delete '/admin/comments/:id' do |id|
      Comment.get(id).destroy
      redirect "/admin/comments"
    end

    # category
    get '/admin/categories' do
      login_required
      @categories = Category.all.
                    page(params[:page], :per_page => settings.admin_per_page)
      render_any :'categories/index'
    end
    
    get '/admin/categories/new' do
      login_required
      @category = Category.new
      @categories = [nil, t.not_select] + Category.all.map {|c| [c.id, c.title] }
      render_any :'categories/new'
    end
    
    post '/admin/categories' do
      login_required
      @category = Category.new(params['category'])
      @category.user = current_user
      if @category.save
        redirect '/admin/categories'
      else
        render_any :'categories/new'
      end
    end
    
    get '/admin/categories/:id/edit' do |id|
      login_required
      @category = Category.get(id)
      render_any :'categories/edit'
    end
    
    put '/admin/categories/:id' do |id|
      login_required
      @category = Category.get(id)
      if @category.update(params['category'])
        redirect "/admin/categories/#{id}/edit"
      else
        render_any :'categories/edit'
      end
    end

    delete '/admin/categories/:id' do |id|
      Category.get(id).destroy
      redirect "/admin/categories"
    end

    # users
    get '/admin/users' do
      login_required
      @users = User.all(:order => :created_at.desc).
                    page(params[:page], :per_page => settings.admin_per_page)
      render_any :'users/index'
    end
    
    get '/admin/users/new' do
      login_required
      @user = User.new
      render_any :'users/new'
    end
    
    post '/admin/users' do
      login_required
      @user = User.new(params['user'])
      if @user.save
        redirect '/admin/users'
      else
        render_any :'users/new'
      end
    end
    
    get '/admin/users/:id/edit' do |id|
      login_required
      @user = User.get(id)
      render_any :'users/edit'
    end
    
    put '/admin/users/:id' do |id|
      login_required
      @user = User.get(id)
      if @user.update(params['user'])
        redirect "/admin/users/#{id}/edit"
      else
        render_any :'users/edit'
      end
    end

    delete '/admin/users/:id' do |id|
      User.get(id).destroy
      redirect "/admin/users"
    end
 
    # theme
    get '/admin/themes' do
      login_required
      @themes =
        Dir.glob("#{settings.theme}/*").map do |f|
          title = f.split('/').last
          s = Dir.glob("#{f}/screenshot.*")
          screenshot = s.empty? ? nil : "/#{s.first.split('/')[-3, 3].join('/')}"
          OpenStruct.new(:title => title, :screenshot => screenshot)
        end
      render_any :'themes/index'
    end

    put '/admin/themes' do
      site = Site.first
      site.update(:theme => params[:title])
      redirect '/admin/themes'
    end

    # plugin
    get '/admin/plugins' do
      login_required
      render_any :'plugins/index'
    end

    # site
    get '/admin/site/edit' do
      login_required
      @site = Site.first
      render_any :'site/edit'
    end

    put '/admin/site' do
      login_required
      if Site.first.update(params['site'])
        redirect '/admin/site/edit'
      else
        render_any :'site/edit'
      end
    end

    # index
    get '/' do
      @theme_types << :index
      @theme_types << :entries

      @posts = Post.page(params[:page], :per_page => settings.per_page)

      @bread_crumbs = BreadCrumb.new
      @bread_crumbs.add('Home', '/')

      logger.debug "root: #{settings.root}"
      logger.debug "public: #{settings.public}"
      logger.debug "views: #{settings.views}"
      logger.debug "theme: #{settings.theme}"

      render_detect :index, :entries
#      render_any :entries
    end

    get '/index.atom' do
      @posts = Post.page(params[:page], :per_page => settings.per_page)
      content_type 'application/atom+xml', :charset => 'utf-8'
      builder :'system/index'
    end

    # search
    get '/search/' do
      @theme_types << :search
      @theme_types << :entries

      @query = params[:query]
      @posts = Post.search(@query).
                    page(params[:page], :per_page => settings.per_page)

      @title = "Search by #{@query} - #{@site.title}"

      @bread_crumbs = BreadCrumb.new
      @bread_crumbs.add('Home', '/')
      @bread_crumbs.add('Search', '/search/')

      render_detect :search, :entries
    end

    # category
    get '/category/*/' do |path|
      @theme_types << :category
      @theme_types << :entries

      category_title = path.split('/').last
      @category = Category.get_by_fuzzy_slug(category_title)
      return 404 if @category.nil?
      @posts = Post.all(:category => @category).
                    page(params[:page], :per_page => settings.per_page)

      @title = "#{@category.title} - #{@site.title}"

      @bread_crumbs = BreadCrumb.new
      @bread_crumbs.add('Home', '/')
      @category.ancestors.each do |cat|
        @bread_crumbs.add(cat.name, cat.link)
      end
      @bread_crumbs.add(@category.title, @category.link)

      render_detect :category, :entries
    end

    # tag
    get '/tags/:tag/' do |tag|
      @theme_types << :tag
      @theme_types << :entries

      @tag = Tag.first(:name => tag)
      return 404 if @tag.nil?
      @posts = Post.all(:id.in => @tag.taggings.map {|o| o.taggable_id }).
                    page(params[:page], :per_page => settings.per_page)
      @title = "#{@tag.name} - #{@site.title}"

      @bread_crumbs = BreadCrumb.new
      @bread_crumbs.add('Home', '/')
      @bread_crumbs.add(@tag.name, @tag.link)

      render_detect :tag, :entries
    end

    # monthly
    get %r{^/([\d]{4})/([\d]{2})/$} do |year, month|
      @theme_types << :monthly
      @theme_types << :entries

      year, month = year.to_i, month.to_i
      @posts = Post.all(:created_at.gte => DateTime.new(year, month)).
                    all(:created_at.lt => DateTime.new(year, month) >> 1).
                    page(params[:page], :per_page => settings.per_page)

      @title = "#{year}/#{month} - #{@site.title}"

      @bread_crumbs = BreadCrumb.new
      @bread_crumbs.add('Home', '/')
      @bread_crumbs.add("#{year}", "/#{year}/")
      @bread_crumbs.add("#{year}/#{month}", "/#{year}/#{month}/")

      render_detect :monthly, :entries
    end

    # yearly
    get %r{^/([\d]{4})/$} do |year|
      @theme_types << :yearly
      @theme_types << :entries

      year = year.to_i
      @posts = Post.all(:created_at.gte => DateTime.new(year)).
                    all(:created_at.lt => DateTime.new(year + 1)).
                    page(params[:page], :per_page => settings.per_page)

      @title = "#{year} - #{@site.title}"

      @bread_crumbs = BreadCrumb.new
      @bread_crumbs.add('Home', '/')
      @bread_crumbs.add("#{year}", "/#{year}/")

      render_detect :yearly, :entries
    end

    # entry
    get %r{^/([0-9a-zA-Z-]+)$} do |id_or_slug|
      @theme_types << :entry

      @entry = Entry.get_by_fuzzy_slug(id_or_slug)
      return 404 if @entry.blank?

      @title = "#{@entry.title} - #{@site.title}"

      @bread_crumbs = BreadCrumb.new
      @bread_crumbs.add('Home', '/')
      if @entry.category
        @entry.category.ancestors.each do |cat|
          @bread_crumbs.add(cat.name, cat.link)
        end
        @bread_crumbs.add(@entry.category.title, @entry.category.link)
      end
      @bread_crumbs.add(@entry.title, @entry.link)

      render_any :entry
    end

    # comment
    post %r{^/([0-9a-zA-Z-]+)$} do |id_or_slug|
      @theme_types << :entry

      @entry = Entry.get_by_fuzzy_slug(id_or_slug)
      return 404 if @entry.blank?

      @comment = @entry.comments.new(params['comment'])
      if @comment.save
        redirect @entry.link
      else
        render_any :entry
      end
    end

    not_found do
      logger.debug "path_info: #{request.path_info}"
      logger.debug "views, theme: #{options.views}, #{options.theme}"
      haml :'system/404', :layout => false
    end

    error do
      'Error: ' + env['sinatra.error'].name
    end
  end
end
