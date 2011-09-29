require 'cinch'
require 'net/http'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = 'irc.freenode.org'
    c.channels = ['#ix2-bot']
    c.nick = 'interbot'
  end

  on :message, "hello" do |m|
    nick = m.user.nick
    match = nick.match(/fooo+/)
    if match.nil? || match[0] != nick
      m.reply "Hello, #{nick}"
    else
      m.reply "GTFO, #{nick}"
    end
  end
  
  on :message, /^#{self.nick} push (.*) to (.*)$/ do |m|
    matches = m.params[1].scan(/push (.*) to (.*)/)[0]
    project_name = matches.join(' ')
    m.reply "Pushing #{matches[0]} to #{matches[1]} by building #{project_name} on Hudson"
    url = URI.parse("http://jaws:8080/job/#{project_name.gsub(' ', '%20')}/build?delay=0sec")
    request = Net::HTTP::Get.new(url.path)
    Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
  end

  on :message, /^#{self.nick} build (.*)$/ do |m|
    project_name = m.params[1].scan(/build (.*)/)[0][0]
    m.reply "Building #{project_name}"
    url = URI.parse("http://jaws:8080/job/#{project_name.gsub(' ', '%20')}/build?delay=0sec")
    request = Net::HTTP::Get.new(url.path)
    Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
  end

  on :message, /^#{self.nick} pick lunch$/ do |m|
    lunches = ["Sitar", "Jason's Deli", "Dreamland", "Sweet Tea", "Rogue", "Acapulco", "Rojo", "Niki's West", "Moe's BBQ"]
    if [1,4].include?(Time.now.wday)
      10.times do
        lunches << "Sitar"
      end
    end
    m.reply "What about #{lunches.sort_by{rand}[0]}?"
  end
end

bot.start
