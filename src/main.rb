require_relative "helpers"

# Setting up Transitional Video Download Dir for downloading Drive Videos
TMP_VIDEO_DOWNLOAD_PATH = "#{Dir.home}#{Settings.tmp_video_download_path}".freeze
FileUtils.mkdir_p(TMP_VIDEO_DOWNLOAD_PATH)

# path to client_secrets.json & tokens.yaml & SCOPES
CLIENT_SECRETS_PATH =
  File.join(Dir.home, ".google_cred", "client_secrets_server.json")
YOUTUBE_CLIENT_SECRETS_PATH =
  File.join(Dir.home, ".google_cred", "youtube_client_secrets.json")
YOUTUBE_CREDENTIALS_PATH =
  File.join(Dir.home, ".google_cred", "youtube_tokens.yaml")

# ["https://www.googleapis.com/auth/spreadsheets", "https://www.googleapis.com/auth/drive"]
DRIVE_SHEETS_SCOPE = [
  Google::Apis::SheetsV4::AUTH_SPREADSHEETS,
  Google::Apis::DriveV3::AUTH_DRIVE
].freeze

# ["https://www.googleapis.com/auth/youtube"]
YOUTUBE_SCOPE = [
  Google::Apis::YoutubeV3::AUTH_YOUTUBE
].freeze
OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze # for youtube authorization

# Sheet V4 Service
sheets_service = Google::Apis::SheetsV4::SheetsService.new
sheets_service.authorization = Help.authorize(
  CLIENT_SECRETS_PATH, DRIVE_SHEETS_SCOPE
)

# Drive V3 Service
drive_service = Google::Apis::DriveV3::DriveService.new
drive_service.authorization = Help.authorize(
  CLIENT_SECRETS_PATH, DRIVE_SHEETS_SCOPE
)

# Youtube V3 Service
youtube_service = Google::Apis::YoutubeV3::YouTubeService.new
youtube_service.authorization = Help.authorize_youtube(
  YOUTUBE_CREDENTIALS_PATH, YOUTUBE_CLIENT_SECRETS_PATH, YOUTUBE_SCOPE
)

# spreadsheet has many sheets
spreadsheet_id = /[-\w]{25,}/.match(Settings.gdoc_sheet_url).to_s

# Column Letter to Coordinate
c_col = Help.char_to_ord(Settings.eng_video_id) # ENG Youtube video id
d_col = Help.char_to_ord(Settings.title_col) # Translated Youtube video title
e_col = Help.char_to_ord(Settings.description_col) # Translated Youtube video description
f_col = Help.char_to_ord(Settings.course_description_col) # Translated Youtube video course description
g_col = Help.char_to_ord(Settings.markers_col) # Markers/Tags
h_col = Help.char_to_ord(Settings.ka_youtube_url_col) # Newly generated Youtube video id

range = Help.create_range( # Example: "Sheet1!A3:C10"
  Settings.range_starting_col,
  Settings.first_row,
  Settings.range_ending_col,
  Settings.last_row
)

# Rows that have videos that haven't been uploaded
response_range_array = Help.get_range(
  range,
  spreadsheet_id,
  sheets_service
).values

# [row_index, title, description, eng_video_id, course_description, playlist, markers]
selected_rows_array = []
response_range_array.each.with_index(Settings.first_row) do |row, index|
  title = row[d_col] # Column D
  description = row[e_col] # Column E
  eng_video_id = row[c_col] # Column C
  course_description = row[f_col] # Coulmn F
  markers = row[g_col] # Column G

  # Select only videos that haven't been uploaded to Youtube yet
  if row[h_col].nil? || row[h_col].empty?
    selected_rows_array << [index, title, description, eng_video_id, course_description, markers]
  end
end

puts "*************************************************************************"
puts "Starting to upload #{selected_rows_array.size} internationalized Videos."

def generate_description(description, eng_video_id, course_description)
  <<~EOS
    #{description}

    Видеоурок на английски от Кан Академия: https://www.youtube.com/watch?v=#{eng_video_id}

    #{course_description}

    За Кан Академия: Кан Академия предлага практически упражнения, учебни видеа и персонализирана учебна дъска, която позволява на учениците да учат на собствена скорост извън класната стая. Справяме се с математиката, науката, компютърното програмиране, историята, историята на изкуството, икономиката и други. Нашите математически мисии превеждат учениците от детската градина до математиката за напреднали, като използват адаптивна най-съвременна технология, която идентифицира силните страни и пропуските в обучението. Също така си партнираме с институции като НАСА, Музея на модерното изкуство, Калифорнийската академия на науките и МИТ, за да предложим специализирано съдържание.

    Безплатно. За всички. Завинаги.
    #YouCanLearnAnything, #МожешДаНаучишВсичко

    Абонирай се за Кан Академия България https://www.youtube.com/channel/UCHNKwF_1cac1ebnOtrdXwVw?sub_confirmation=1.
    Абонирай се за Кан Академия
    https://www.youtube.com/channel/UC4a-Gbdw7vOaccHmFo40b9g?sub_confirmation=1
  EOS
end

# Main Loop
# [row_index, title, description, eng_video_id, course_description, markers]
selected_rows_array.each do |row|
  puts
  puts "Searching for file on Drive by name: #{row[3]}"
  # Find Video on Drive to Upload on Youtube # fields: id, name, mimeType, owners
  response = drive_service.list_files(
    q: "name='#{row[3]}.mp4'",
    spaces: "drive",
    fields: "files(id, name, owners)"
  )

  puts "Found #{response.files.count} File(s)"
  response.files.each do |file|
    puts "-- ID: #{file.id}"
    puts "--- Name: #{file.name}"
    puts "---- Owner? #{file.owners.first.to_h[:me]}"
    puts
  end

  vid = response.files.map(&:to_h).select { |x| x[:owners].first unless x.nil? }
  vid_name = vid.first[:name]
  vid_id = vid.first[:id]
  puts "This is the name & ID of file owned by you: '#{vid_name}' - '#{vid_id}'"

  puts
  puts "Checking if '#{vid_name}' already exists in '#{TMP_VIDEO_DOWNLOAD_PATH}'"
  puts
  if File.file?("#{TMP_VIDEO_DOWNLOAD_PATH}#{vid_name}")
    puts "'#{vid_name}' already exists in '#{TMP_VIDEO_DOWNLOAD_PATH}'"
  else
    puts "Started Downloading '#{vid_name}'"
    drive_service.get_file(vid_id, download_dest: "#{TMP_VIDEO_DOWNLOAD_PATH}#{vid_name}")
    puts "Finished Downloading '#{vid_name}' to '#{TMP_VIDEO_DOWNLOAD_PATH}'"
  end

  vid_title = row[1]
  vid_description = generate_description(row[2], # description
                                         row[3], # ENG video id
                                         row[4]) # course description

  begin
    puts "Started Uploading '#{vid_name}'"
    video_upload_resp = Help.insert_video(
     youtube_service,
     Help.create_video_options(vid_title, vid_description, row[5], Settings.global_privacy),
     "snippet, status",
     upload_source: "#{TMP_VIDEO_DOWNLOAD_PATH}#{vid_name}",
     content_type: "video/mp4",
     options: {
       open_timeout_sec: 300
     }
    )
    puts "Finished Uploading '#{vid_name}'"
  rescue Google::Apis::TransmissionError
    puts "Failed to Upload #{vid_name}"
    next
  end

  # Update newly generated URL column
  uploaded_vid_id = video_upload_resp.to_h[:id]
  h_col_data = Help.create_value_range([[uploaded_vid_id]])
  Help.update_range("#{Settings.ka_youtube_url_col}#{row[0]}", h_col_data, spreadsheet_id, sheets_service, "USER_ENTERED")
end
# Main Loop

puts "Operation Finished."
puts "*************************************************************************"
