require 'rubygems'
require 'sinatra'
require 'rest_client'
require 'uri'

URL = "http://localhost:3000/api" 

enable :sessions

helpers do 
  def acessar *parametros
    if parametros.first != "autenticar"
      parametros = [parametros[0], session[:token]] + parametros[1..-1]
    end
    url = ([URL] + (parametros.collect{|p| URI.encode(p)})).join("/")
    puts "acessando: #{url}"
    data = RestClient.get url
    if data =~ /^ERRO: 003/
      renovar_token
      return acessar *parametros
    end
    data
  end
  def renovar_token
    session[:token] = acessar "autenticar", session[:login], session[:senha]
  end
  def envia_sms(telefone, mensagem)
    acessar "envia_sms", telefone, mensagem
  end
  def ver_status_mensagem(id)
    acessar "status", id
  end
end

get "/" do
  if not session[:token]
    redirect "/login"
  else
    erb :index
  end
end

get "/login" do 
  erb :login
end

post "/login" do 
  session[:login] = params[:login]
  session[:senha] = params[:senha]
  renovar_token
  redirect "/" 
end

post "/envia_sms" do 
  id = envia_sms(params[:telefone], params[:mensagem])
  puts id
  (session[:mensages] ||= {})[id] = {
    :telefone => params[:telefone], 
    :mensagem => params[:mensagem]
  }
  redirect "/" 
end

get "/status/:id" do
  ver_status_mensagem params[:id]
end
