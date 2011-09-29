require 'cinch'
require 'net/http'
require 'barometer'
require 'open-uri'
require 'rubygems'
require 'hpricot'

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

  on :message, /^#{self.nick} weather$/ do |m|
    barometer = Barometer.new("Birmingham, AL")
    weather = barometer.measure
    m.reply "Currently #{weather.current.temperature} and #{weather.current.icon}"
  end

  on :message, /^#{self.nick} doorman$/ do |m|
    employee_ids = {:frankh => 9999, :davecow => 1223, :CodyC => 3994, :robbihun1 => 3938, :Ash_Work => 3974, :keithtronic => 3904}
    emp_in, emp_out = [], []
    employee_ids.keys.each do |employee|
      url = "http://doorman/reports/employeeReport.aspx?employeeID=#{employee_ids[employee]}"
      puts "#{employee}: #{url}"
      doc = open(url) {|f| Hpricot(f)}
      status = doc.search("#page_content > table").last.search("tr").last.search("td")[1].inner_html
      if status.match(/In the Office/)
        emp_in << employee
      else
        emp_out << employee
      end
    end
    m.reply "In: #{emp_in.join(', ')}"
    m.reply "Out:#{emp_out.join(', ')}"
  end

end

bot.start
