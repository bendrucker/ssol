require "rubygems"
require "mechanize"

class SSOL

	def initialize user
		@agent = Mechanize.new
		@user = user
		@session = String.new

		login
	end

	class SSOLError < StandardError; end

	BASE_URL = 'https://ssol.columbia.edu/cgi-bin/ssol/'

	PAGES = {
		:registration_appointments => 'tran%25.5B1%25.5D%25.5Fentry=student&tran%25.5B1%25.5D%25.5Ftran%25.5Fname=spra',
		:class_search => 'tran%.5B1%.5D%.5Fact=Search&tran%.5B1%.5D%.5Ftran%.5Fname=sreg'
	}

	DAYS = {
		:Mo => 'Monday',
		:Tu => 'Tuesday',
		:We => 'Wednesday',
		:Th => 'Thursday',
		:Fr => 'Friday'
	}

	private :login, :parse_class, :get

	# If page is passed, login to that page. Otherwise, get home and login. 
	def login page = nil
		page ||= @agent.get BASE_URL
		login_form = page.forms.first
		login_form.set_fields :u_pw => @user[:password]
		if login_form.has_field?('u_id') then login_form.set_fields :u_id => @user[:id] end
		page = login_form.submit
		if page.logged_in?
			# Session session ID for future page requests and return page
			@session = page.uri.path[1..-1].split('/')[-1]
			page
		else
			puts "Login failed"
		end		
	end

	# Gets a page within SSOL via names defined in PAGES
	def get page_names
		url = "#{BASE_URL}#{@session}/?#{PAGES[page_names]}"
		page = @agent.get url
		page = login(page) unless page.logged_in?
		page
	end

	# Returns an array of registration appointments with :start and :end keys
	def registration_appointments
		page = get :registration_appointments
		appointments = []
		page.search('table.DataGrid tr.clsDataGridData').each do |tr|
			start_time = Time.parse tr.children[0].text
			end_time = Time.parse tr.children[1].text
			appointments << {
				:start => start_time,
				:end => end_time
			}
		end
		appointments
	end

	# Returns whether the current time (or a passed Time object) is a registration appointment
	def registration_appointment? time = Time.now
		true if not registration_appointments.select { |appointment|
			(appointment[:start]..appointment[:end]).cover?(time)
		}.empty?
	end

	def query_class query, options = {}
		page = get :class_search
		search_form = page.form_with(:name => 'Search')
		search_form.field_with(:name => 'tran[1]_ss').value = query
		results_page = search_form.submit
		query_result = []

		results_page.search('tr.cls0, tr.cls2').each do |result|
			query_result << parse_class(result)
		end
		query_result
	end

	def parse_class class_row
		columns = class_row.css('td')
		title_line_one = columns[1].children.first.text.split(" ")
		title_line_two = columns[1].children.last.text
		if not columns[4].text.empty?
			time_location = columns[4].text.split
			time = time_location[0].split("-")
		end	
		class_hash = {
			:call_number => columns.at_css('.regb') || columns[0].text,
			:id => "#{title_line_one[0]} #{title_line_one[1]}",
			:title => title_line_two.titleize.split.join(" "),
			:section => title_line_one[2][-3..-1],
			:instructor => columns[2].text.split.join(" "),
			:days => columns[3].text.split.map!{|day| DAYS[day.to_sym]},
			:status => columns[6].text
		}

		# Add optional parameters that may be returned blank

		class_hash[:time] = {:begin => time[0], :end => time[1]} if time
		class_hash[:location] = {:building => time_location[1], :room_number => time_location[2]} if time_location

		class_hash	
	end
		
end

# Extends Mechanize page class to determine various attributes of a returned Page object

class Mechanize::Page
	def logged_in?
		true unless title.include? 'Log in'
	end
	def is_home?
		true if title.include? 'Menu'
	end	
end

# Uses Facets to convert capitalized strings to title case

require 'facets/string/titlecase'

class String
  def titleize
    split(/(\W)/).map(&:capitalize).join
  end
end