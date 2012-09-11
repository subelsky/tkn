# encoding: utf-8

slide <<-EOS, :center
\e[1mRuby Dependencies, Notifications, and Adjustments\e[0m


Mike Subelsky
@subelsky


(slides by https://github.com/fxn/tkn)
EOS

slide <<-EOS, :center
How do you connect your objects?
EOS

slide <<-EOS, :code
# constructor arguments

class DecryptedString
  def initialize(secret_str)
    @secret_str = secret_str
  end
end
EOS

slide <<-EOS, :code
# setters

agent = Mechanize.new
agent.log = Logger.new(STDOUT)
EOS

slide <<-EOS, :code
# direct instantiation

class SportsCar < Car
  def initialize
    @engine = Engine.new(:v6)
  end
end
EOS

slide <<-EOS, :code
# callbacks

request = Typhoeus::Request.new(url,options)
request.on_complete do |response|
  if response.success?
    xm = Nokogiri::XML(response.body)
  end
end
EOS

slide <<-EOS, :code
# reference a global constant

class DataFetcher
  def fetch(params)
    Rails.logger.info "Fetching \#{params}"
  end
end
EOS

slide <<-EOS, :center
Growing Object-Oriented Software, Guided by Tests
EOS

slide <<-EOS, :block
Object Peer Stereotypes

  * Dependencies
  * Notifications
  * Adjustments
EOS

section "Dependencies" do
  slide <<-EOS, :block
  “Services that the object requires from its
  peers so it can perform its responsibilities.
  The object cannot function without these
  services. It should not be possible to create
  the object without them.”
  EOS

  slide <<-EOS, :code
  class HttpRequest
    attr_reader :typhoeus_request

    def initialize(url,options = {})
      @typhoeus_request = Typhoeus::Request.new(url,options)
      @success_callbacks = []
      @failure_callbacks = []
    end
  end
  EOS

  slide <<-EOS, :block
  Rules of thumb:

  * Always pass dependencies into the constructor
  * No reasonable defaults for dependencies
  EOS
end

section "Notifications" do
  slide <<-EOS, :block
  “Peers that need to be kept up to date with the
  object’s activity. The object will notify
  interested peers whenever it changes state or
  performs a significant action...the object
  neither knows nor cares which peers are
  listening.”
  EOS

  slide <<-EOS, :code
def initialize(url,opt = {})
  @typhoeus_request = Typhoeus::Request.new(url,opt)
  @success_callbacks = []
  @failure_callbacks = []

  @typhoeus_request.on_complete do |response|
    if response.success?
      success_callbacks.each do |sc|
        sc.call(response)
      end
    elsif response.timed_out?
      failure_callbacks.each do |fc|
        fc.call("Request timed out for \#{url}")
      end
    end
  end
end
  EOS

  slide <<-EOS, :code
def on_success(&block)
  success_callbacks << block
end

def on_failure(&block)
  failure_callbacks << block
end

private

attr_reader :success_callbacks, :failure_callbacks
  EOS

  slide <<-EOS, :code
stats_request.on_success do |body|
  xml = Nokogiri::XML(body)

  xml.xpath("//Audience").each do |aud|
    key = aud.at("id").text
    # do stuff with key
  end

  @success = true
end
  EOS

  slide <<-EOS, :code
  # blocks are good for error notifications

  data_fetcher.fetch do |err_msg|
    puts "We couldn't complete our task because of \#{err_msg}"
    return
  end

  # good way to avoid returning nil!
  EOS

  slide <<-EOS, :code
  # log files are often notifications
  agent = Mechanize.new
  agent.log = Logger.new(STDOUT)
  EOS
end

section "Adjustments" do
  slide <<-EOS, :block
  “Peers that adjust the object’s behavior to the
  wider needs of the system. This includes policy
  objects that make decisions on the object’s behalf
  ...and component parts of the object if it’s a
  composite.”
  EOS

  slide <<-EOS, :code
class DataFetcher
  attr_writer :auth_agent, :shaz_fetcher

  def fetch(credentials)
    auth_agent.login(credentials) do |msg|
      logger.warn "Could not login due to \#{msg}"
      return
    end

    shaz_fetcher.fetch(auth_agent.token) do |msg|
      logger.warn "Could not fetch shaz due to \#{msg}"
    end
  end
  EOS

  slide <<-EOS, :code
  private

  def auth_agent
    @auth_agent ||= AuthorizationAgent.new
  end

  def shaz_fetcher
    @shaz_fetcher ||= ShazFetcher.new
  end
end
  EOS

  slide <<-EOS, :code
  # strategy pattern is usually an adjudment

  class DataFetcher
    attr_writer :admin_checker

    def fetch(query_params)
      if !admin_checker.valid?(query_params)
        yield "You are not authorized"
        return
      end

      # proceed to fetch data
    end

    private

    def admin_checker
      @admin_checker ||= AdminChecker.new
    end
  end
  EOS
end

slide <<-EOS, :code
class HttpRequestService
  attr_writer :hydra

  def request(url,options = {})
    HttpRequest.new(url,options).tap do |http_request|
      hydra.queue(http_request.typhoeus_request)
    end
  end

  def run
    hydra.run
  end

  private

  def hydra
    @hydra ||= Typhoeus::Hydra.new
  end
end
EOS

slide <<-EOS, :block
Dependency injection containers can help

  * http://bit.ly/eQXyNq # Jim Weirich's article
  * http://rubygems.org/gems/dim # my gem
EOS

slide <<-EOS, :code
AppContainer = Dim::Container.new

# snip

AppContainer.register(:logger) do |c|
  if c.test?
    Logger.new("\#{c.root}/log/\#{c.env}.log")
  elsif c.production?
    Sidekiq.logger.tap { |l| l.level = ENV["DEBUG"].present? ? Logger::DEBUG : Logger::INFO }
  else
    Logger.new(STDOUT)
  end
end
EOS

slide <<-EOS, :code
AppContainer.register(:mechanize) do |c|
  Mechanize.new do |agent|
    agent.log = c.logger
    agent.user_agent_alias = "Mac Safari"
    agent.keep_alive = false
  end
end

AppContainer.register(:salesforce_client) do |c|
  require "databasedotcom"
  Databasedotcom::Client.new({
    client_id: c.salesforce_consumer_key,
    client_secret: c.salesforce_consumer_secret
  })
end
EOS

section "Conclusion" do
  slide <<-EOS, :block
  “What matters most is the context in which the
  collaborating objects are used."
  EOS

  slide <<-EOS, :center
  Questions?

  mike@subelsky.com
  EOS

  slide <<-EOS, :center
  PS I'm starting a company (adstaq.com). Join us!
  EOS
end
