require 'plivo'
require 'yaml'

module Phone
  extend self

  tokens = YAML.load File.read('tokens.yml')

  AUTH_ID    = tokens[:auth_id]
  AUTH_TOKEN = tokens[:auth_token]
  PHONE      = Plivo::RestClient.new AUTH_ID, AUTH_TOKEN
  NUMBER     = tokens[:number]

  def sms(opts={})
<<<<<<< HEAD
    #p [opts[:to], opts[:body]]
    #return unless opts[:to]
    #PHONE.messages.create NUMBER, [opts[:to]], opts[:body]
=======
    return unless opts[:to]
    PHONE.messages.create NUMBER, [opts[:to]], opts[:body]
>>>>>>> refs/remotes/origin/master
  end
end
