require 'dotenv'
require 'intercom'
require 'slim'
require 'stringio'

Dotenv.load

CURRENT_PATH = File.dirname(__FILE__)
EXPORT_PATH = File.join(CURRENT_PATH, 'exported')
TEMPLATES_PATH = File.join(CURRENT_PATH, 'templates')

TEMPLATE_ARTICLE = 'article.slim'
TEMPLATE_INDEX = 'index.slim'

TEMPLATE_OPTIONS = { pretty: true, sort_attrs: true, format: :html, disable_escape: true }.freeze

Slim::Engine.set_options(TEMPLATE_OPTIONS)

# With an OAuth or Personal Access token:
INTERCOM_CLIENT = Intercom::Client.new(token: ENV['INTERCOM_TOKEN'])

articles = INTERCOM_CLIENT.articles.all.to_h { |a| [a.id, a] }
collections = INTERCOM_CLIENT.collections.all.to_h { |a| [a.id, a] }

FileUtils.rm_rf(File.join(EXPORT_PATH))
FileUtils.mkdir_p(File.join(EXPORT_PATH, 'articles'))

articles.values.each do |article|
  File.open(File.join(EXPORT_PATH, 'articles', "#{article.id}.html"), 'w+') do |f|
    f << Slim::Template.new(File.join(TEMPLATES_PATH, TEMPLATE_ARTICLE), TEMPLATE_OPTIONS).render(article)
  end
end

tree = {}

articles.values.each do |article|
  id = article.id.to_s
  parent_id = article.parent_id.to_s

  if parent_id.nil? || parent_id.empty?
    tree[id] ||= {}
    tree[id][:leaves] ||= {}
    tree[id][:article] = article

    next
  end

  puts [parent_id, id].join('-')
  tree[parent_id] ||= { article: articles[parent_id], collection: collections[parent_id], leaves: {} }
  tree[parent_id][:leaves][id] = { article: article }
end

File.open(File.join(EXPORT_PATH, 'index.html'), 'w+') do |f|
  f << Slim::Template.new(File.join(TEMPLATES_PATH, TEMPLATE_INDEX), TEMPLATE_OPTIONS).render(Hash, tree: tree)
end
