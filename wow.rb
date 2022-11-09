require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"
require "sinatra/content_for"
require "yaml"

configure do
  enable :sessions
  set :session_secret, 'secret123456789012345678901234567890123456789012345678901234567890'
  set :erb, :escape_html => true
end

before do
  @categories = YAML.load(File.read("categories.yml"))
  @quotes = YAML.load(File.read("quotes.yml"))
  @contributors = YAML.load(File.read("contributors.yml"))
end

helpers do
  def author_name(filename)
    @contributors[filename][:name]
  end
  
  def author_age(filename)
    @contributors[filename][:age]
  end

  def author_location(filename)
    @contributors[filename][:location]
  end
end

def data_path
  if env["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def render_markdown(markdown_text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(markdown_text)
end

def create_file_name(category)
  time_stamp = Time.now.to_i.to_s
  "#{category}#{time_stamp}.md"
end

def files_in_a_category(category)
  matched_files = []
  match_string = "#{category}*"
  Dir.foreach(data_path) do |filename|
    matched_files << filename if File.fnmatch(match_string, filename)
  end
  matched_files
end

def available_categories
  categories = []
  @categories.each do |category|
    categories << category unless files_in_a_category(category).empty?
  end
  categories
end

get "/" do
  erb :index
end

post "/new" do
  file_name = create_file_name(params[:category])
  path = File.join(data_path, file_name)
  File.write(path, params[:content])
  age = params[:age].to_i
  @contributors[file_name] = { name: params[:name], age: age, location: params[:location] }
  File.write('contributors.yml', @contributors.to_yaml)
  session[:message] = "Your words have been recorded."
  redirect "/"
end

get "/inspiration" do
  erb :inspiration
end

get "/view_inspiration" do
  @target_filename = files_in_a_category(params[:category]).sample
  path = File.join(data_path, @target_filename)
  content = File.read(path)
  @file_content = render_markdown(content)
  erb :view_inspiration
end