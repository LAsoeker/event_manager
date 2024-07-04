require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = File.read('secret.key').strip

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.gsub(/\D/, '')
  if phone_number.length == 11 && phone_number[0] == '1' 
    phone_number[1..10]
  elsif phone_number.length == 10 
    phone_number
  else
    "Bad phone number #{phone_number}"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
    filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def most_common_hour
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )
  hours = []
  contents.each do |row|
    hour = Time.strptime(row[:regdate], '%m/%d/%Y %k:%M').strftime('%k')
    hours.push(hour)
  end

  hours_count = Hash.new(0)
  hours.each{|hour| hours_count[hour] += 1}

  most_common = hours_count.max_by { |hour, count| count }

  puts "The most common hour is #{most_common[0]}:00 with #{most_common[1]} occurrences."
end

def most_common_week_day
  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
  )

week_days = {
  0 => "Sunday",
  1 => "Monday",
  2 => "Tuesday",
  3 => "Wednesday",
  4 => "Thursday",
  5 => "Friday",
  6 => "Saturday"
}

  days = []
  contents.each do |row|
    time = Time.strptime(row[:regdate], '%m/%d/%Y %k:%M')
    year = time.year
    month = time.month
    day = time.day
    week_day = Date.new(year, month, day).wday
    days.push(week_day)
  end

  days_count = Hash.new(0)
  days.each{|day| days_count[day] += 1}

  most_common = days_count.max_by { |day, count| count }

  puts "The most common day is #{week_days[most_common[0]]} with #{most_common[1]} occurrences."
end

if File.exist? "event_attendees.csv"
  contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
  )

  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter

  contents.each do |row|
    id = row[0]
    name = row [:first_name]
    phone_number = clean_phone_number row[:homephone]
    zipcode = clean_zipcode(row[:zipcode])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter id, form_letter
  end
end

most_common_hour
most_common_week_day
