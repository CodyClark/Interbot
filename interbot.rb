require 'cinch'
require 'net/http'
require 'barometer'
require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'whois'
require 'twilio-ruby'
require 'nokogiri'
require 'cgi'
require 'gmail' #ix2bot@gmail.com/interbot11

bot = Cinch::Bot.new do
  @bot = self;

  configure do |c|
    c.server = 'irc.freenode.org'
    c.channels = ['#ix2-bot','#ix2-2']
    c.nick = 'interbot'
  end

  helpers do
    def urban_dict(query)
	  url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(query)}"
	  puts url
	  CGI.unescape_html Nokogiri::HTML(open(url)).at("div.definition").text.gsub(/\s+/, ' ') rescue nil
	end
	
	def doorman
  	  employee_ids = {:frankh => 9999, :davecow => 1223, :CodyC => 3994, :robbihun1 => 3938, :Ash_Work => 3974, :keithtronic => 3904, :isau => 3917, :clark => 3965, :monday => 3935}
      emp_in, emp_out = [], []
      employee_ids.keys.each do |employee|
        url = "http://doorman/reports/employeeReport.aspx?employeeID=#{employee_ids[employee]}"
        puts "#{employee}: #{url}"
        doc = open(url) {|f| Hpricot(f)}
	    element = doc.search("#page_content > table").last.search("tr").last.search("td")[1]
        status = element.nil? ? "" : element.inner_html
        if status.match(/In the Office/)
          emp_in << employee
        else
          emp_out << employee
        end
      end
      return {:in => emp_in, :out => emp_out}
	end
  end
  
  on :message, "hello" do |m|
    nick = m.user.nick
    match = nick.match(/^fooo+$/)
	m.reply match.nil? || match[0] != nick ? "Hello, #{nick}" : "GTFO, #{nick}"
  end
  
  on :message, /^#{self.nick} push (.*) to (.*)$/ do |m, project_name, destination|
    project_name = "#{project_name} #{destination}"
    m.reply "Pushing #{matches[0]} to #{matches[1]} by building #{project_name} on Hudson"
    url = URI.parse("http://jaws:8080/job/#{project_name.gsub(' ', '%20')}/build?delay=0sec")
    request = Net::HTTP::Get.new(url.path)
    Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
  end

  on :message, /^#{self.nick} build (.*)$/ do |m, project_name|
    m.reply "Building #{project_name}"
    url = URI.parse("http://jaws:8080/job/#{project_name.gsub(' ', '%20')}/build?delay=0sec")
    request = Net::HTTP::Get.new(url.path)
    Net::HTTP.start(url.host, url.port) {|http| http.request(request)}
  end

  on :message, /^#{self.nick} pick lunch$/ do |m|
    lunches = ["Sitar", "Jason's Deli", "Dreamland", "Sweet Tea", "Rogue", "Acapulco", "Rojo", "Niki's West", "Moe's BBQ"]
    if [1,4].include?(Time.now.wday)
      20.times do
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
    emps = doorman
    m.reply "In: #{emps[:in].join(', ')}"
    m.reply "Out: #{emps[:out].join(', ')}"
  end

  on :message, /^#{self.nick} whois (.*)$/ do |m, domain|
    r = Whois.whois(domain)
	m.reply "#{domain} is available" if r.available?
	if (r.registered?)
	  m.reply "#{domain} was registered on #{r.created_on.strftime("%m%d/%Y")} by #{r.admin_contact.name} (#{r.admin_contact.organization}) through #{r.registrar.name}"
	end
  end
  
  on :message, /^#{self.nick} batsignal$/ do |m|
	weather = Barometer.new("Birmingham, AL").measure
	location = weather.wet? ? 'by the door (chance of rain)' : 'outside'
	emps = doorman
	employees = {
	              :frankh => '2056125241@txt.att.net',
	              :davecow => '2056170775@txt.att.net',
	              :CodyC => '2059601539@txt.att.net',
	              :Ash_Work => '2056173946@txt.att.net',
	              :keithtronic => '3346692522@messaging.sprintpcs.com',
	              :isau => '2056170775@txt.att.net',
	              :clark => '3342216642@vtext.com',
	              :robbihun1 => '2053839379@txt.att.net'
				}
	gmail = Gmail.connect('ix2bot@gmail.com', 'interbot11')
    emps[:in].each do |e|
      unless employees[e].nil?
        gmail.deliver do
  	      to employees[e]
    	  body "Lunch train is leaving - meet #{location}"
    	end
      end
    end
    gmail.logout
	m.reply "Messages sent"
  end
  
  on :channel, /^\/(\w*) rolls dice$/ do |m|
    m.reply "#{m.user.nick} rolls a #{(1..6).sort_by{rand}.first}"
  end
  
  on :message, /^#{self.nick} urban (.*)/ do |m, term|
    m.reply(urban_dict(term) || "No results found")
  end

end

bot.start
