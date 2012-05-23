# coding: utf-8
require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'carrierwave'
require 'carrierwave/datamapper'
require 'rmagick'
require 'json'

set :public_directory, './public'

class ImageUploader < CarrierWave::Uploader::Base
  def store_dir
    'uploads/images'
  end
  def extension_white_list
    %w(jpg jpeg gif png bmp)
  end
  include CarrierWave::RMagick
  version :thumb do
    process :resize_to_fill => [100,74]
  end
  storage :file
end

class Post
  include DataMapper::Resource
  property :id,         Serial
  property :title,      String
  property :body,       Text
end

class UploadedImages
  include DataMapper::Resource
  property :id,    Serial
  property :image, String
  property :thumb, String

  mount_uploader :file, ImageUploader
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite:./db/base.db')
DataMapper.finalize
DataMapper.auto_upgrade!

get '/' do
  'REST приложение на Sinatra <a href="/posts">Перейти к страницам</a>'
end

#List posts
get '/posts' do
  @posts = Post.all
  erb :'index'
end

#Create new Post
get '/posts/new' do
  erb :'posts/new'
end

post '/posts/new' do
  params.delete 'submit'
  @post = Post.create(params)
  redirect '/posts'
end

#Edit post
get '/posts/:id/edit' do
  @post = Post.get(params[:id])
  erb :'posts/edit'
end

#Update post
put '/posts/:id/edit' do
  post = Post.get(params[:id])
  post.title = (params[:title])
  post.body = (params[:body])
  post.save
  redirect '/posts'
end

#Delete post
get '/posts/:id/delete' do
  Post.get(params[:id]).destroy
  redirect '/posts'
end

post '/upload/image' do
  params[:file]
  filename = params[:file][:filename]
  file = params[:file][:tempfile]
  upload = UploadedImages.new
  upload.file = params[:file]
  upload.image = params[:image] = '/uploads/images/' + File.join(filename)
  upload.thumb = params[:thumb] = '/uploads/images/thumb_' + File.join(filename)
  upload.save
  @images = UploadedImages.all
  File.open("public/uploads/images/imageslist.json","w") do |f|
    f.write JSON.pretty_generate(@images)
  end
  '<img src="/uploads/images/' + File.join(filename) + '" />'
end