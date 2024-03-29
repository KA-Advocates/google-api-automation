require "config"
require "googleauth/stores/file_token_store"
require "google/apis/sheets_v4"
require "google/apis/youtube_v3"
require "google/apis/drive_v3"

module Help
  Config.load_and_set_settings(
    "#{Dir.home}/google-api-automation/config/settings.yml"
  )

  def self.authorize_youtube(tokens_file, credentials_file, scope)
    client_id = Google::Auth::ClientId.from_file(credentials_file)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: tokens_file)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)
    user_id = 1
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization: "
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
  ##############################################################################

  # authorization method
  def self.authorize(credentials_file, scope)
    credentials = JSON.parse(File.open(credentials_file, "rb").read)
    authorization = Signet::OAuth2::Client.new(
      token_credential_uri: "https://accounts.google.com/o/oauth2/token",
      audience: "https://accounts.google.com/o/oauth2/token",
      scope: scope,
      issuer: credentials["client_id"],
      signing_key: OpenSSL::PKey::RSA.new(credentials["private_key"], nil)
    )
    authorization.fetch_access_token!
    authorization
  end

  ##############################################################################

  # Create Range. (FirstCol & FirstRow : LastCol & LastRow )
  def self.create_range(fc, rf, cl, rl)
    "#{fc}#{rf}:#{cl}#{rl}"
  end
  ##############################################################################

  # case insensitive char to ASCII
  def self.char_to_ord(char)
    case char
    when /[A-Z]/ then char.ord - "A".ord # 65
    when /[a-z]/ then char.ord - "a".ord # 97
    else raise "Pass only lower or uppercase English characters."
    end
  end
  ##############################################################################

  # create value range
  # 2D array of values, range (optional)
  def self.create_value_range(vals, rang = nil)
    Google::Apis::SheetsV4::ValueRange.new(values: vals, range: rang)
  end
  ##############################################################################

  # get method
  # range, spreadsheet_id, SheetsV4::SheetsServ, major_dimension (ROWS*/COLUMNS)
  def self.get_range(range, spr_id, srvc, major_dimension = "ROWS")
    puts "\nStarted Getting Range *********************************************"
    puts "Getting Range: #{range}"
    resp = srvc.get_spreadsheet_values(
      spr_id,
      range,
      major_dimension: major_dimension
    )
    puts "Got: #{resp.to_h[:values].length} Rows"
    puts "Finished Getting Range ********************************************\n"
    resp
  end
  ##############################################################################

  # update method
  # range, value_range (#create_value_range), spreadsheet_id, SheetsV4::SheetsSe
  def self.update_range(range, value_range, spr_id, srvc, val_inp_opts = "RAW")
    puts "\nStarted Update Range **********************************************"
    puts "Updating #{range}"
    resp = srvc.update_spreadsheet_value(
      spr_id,
      range,
      value_range,
      value_input_option: val_inp_opts
    )
    puts "Updated: #{resp.to_h[:updated_range]}"
    puts "Finished Update Range *********************************************\n"
  end
  ##############################################################################

  # Create Resource Helper for Insert Video Method
  def self.create_resource(properties)
    resource = {}
    properties.each do |prop, value|
      ref = resource
      prop_array = prop.to_s.split(".")
      for p in 0..(prop_array.size - 1)
        is_array = false
        key = prop_array[p]
        if key[-2, 2] == "[]"
          key = key[0...-2]
          is_array = true
        end
        if p == (prop_array.size - 1)
          if is_array
            if value == ""
              ref[key.to_sym] = []
            else
              ref[key.to_sym] = value.split(",")
            end
          elsif value != ""
            ref[key.to_sym] = value
          end
        elsif ref.include?(key.to_sym)
          ref = ref[key.to_sym]
        else
          ref[key.to_sym] = {}
          ref = ref[key.to_sym]
        end
      end
    end
    resource
  end

  # CREATE PLAYLIST OPTIONS snippet[description, tags, default_language,
  # embeddable, license, public_stats_viewable...]
  def self.create_video_options(vid_title,
                                vid_description,
                                tags,
                                vid_privacy_status = "private",
                                category_id = "22")
    { "snippet.category_id" => category_id,
      "snippet.description" => vid_description,
      "snippet.title" => vid_title,
      "snippet.tags" => tags.split(",").map(&:strip),
      "status.privacy_status" => vid_privacy_status }
  end
  ##############################################################################

  # Upload Video
  def self.insert_video(srvc, properties, part, **params)
    puts "\nStarted Inserting Video *******************************************"
    resource = create_resource(properties)
    params = params.delete_if { |_p, v| v == "" }
    resp = srvc.insert_video(part, resource, params)
    # pp resp.to_h
    puts "Finished Inserting Video ******************************************\n"
    resp
  end
  ##############################################################################
end