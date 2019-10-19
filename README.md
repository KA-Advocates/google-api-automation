# Khan Academy video upload automation using Google API
This project helps automate the process of uploading Khan Academy internationalized videos to youtube.

## Getting Started
The project assumes the user has two google accounts:

* **Google Docs SpreadSheet** and **Google Drive** owner account
* **Youtube** Khan Channel owner account
* Windows OS
* **Ruby** (2.6.4) installed

##### Setup for Google Drive and Spreadsheet authentication
With first google account, which has access to Drive and SpreadSheet containing required assets, visit: https://console.developers.google.com/projectcreate
create project and name the project appropriately.

Make sure the newly created project is selected before activating these APIs.

* Activate Google Drive API: `https://console.developers.google.com/apis/library/drive.googleapis.com/`
* Activate Google Spreadsheet API: `https://console.developers.google.com/apis/library/sheets.googleapis.com/`

Next visit: `https://console.developers.google.com/apis/credentials` to create authentication credentials.

* Click Create credentials drop-down and select **Service account key**
* Select Service account drop-down and click **New Service Account**
* Input a descriptive **Service account name** and select **role** to be **Project > Owner**  
* Leave **JSON** radion button selected
* Click Create and save the JSON file.
* Rename downloaded JSON file to `client_secrets_server.json` and move it to `%userprofile%/.google_cred`, where `%userprofile%/` is the home directory of the Windows user.
* Next go to `https://console.developers.google.com/iam-admin/serviceaccounts/`, select the appropriate project and copy the **Service account ID** of the service account, which is a generic email address.
* Now you need to share Google docs spreadsheet with this email the same way you would share any spreadsheet document with a real user, make sure it has edit permissions.
* You will also have to share a Google Drive directory containing internationalized Khan videos with this service account, which then would be temporarily downloaded locally and uploaded to Youtube.

##### Setup for Youtube authentication
With second google account, which has access to Khan Youtube channel, visit: `https://console.developers.google.com/projectcreate`
create project and name the project appropriately.
Make sure the newly created project is selected before activating these APIs.

* Activate Youtube Data API: `https://console.developers.google.com/apis/library/youtube.googleapis.com`

Next visit: `https://console.developers.google.com/apis/credentials` to create authentication credentials.

* Click Create credentials drop-down and select **Service account key**
* Select Service account drop-down and click **New Service Account**
* Input a descriptive **Service account name** and select **role** to be **Project > Owner**  
* Leave **JSON** radion button selected
* Click Create and save the JSON file.
* Rename downloaded JSON file to `youtube_client_secrets_server.json` and move it to `%userprofile%/.google_cred`, where `%userprofile%/` is the home directory of the Windows user.
* Next you will have to setup OAuth credentials for the Youtube authentication. Visit:   `https://console.developers.google.com/apis/credentials/oauthclient`
*
  * If you see this note: `To create an OAuth client ID, you must first     
    set a product name on the consent screen`
  * click `Configure consent screen`
    input Product name into `Product name shown to users` field to be something descriptive, for example: `youtube access for Khan academy's internationalization`.
  * Click `Save`
* Now select `other` under `Application type` radio button list and name it for example `Automation script`
* Click `create` and when you are presented `Oauth client` screen click ok to close it.
* Now a credential should have been added under `OAuth 2.0 client ID`.
* At the end of the row of newly added `OAuth 2.0 client ID` credential, should be a download button that looks like a down arrow, click it and download the file.
* Rename downloaded JSON file to `youtube_client_secrets.json` and move it to `%userprofile%/.google_cred`, where `%userprofile%/` is the home directory of the linux user.

## Prerequisites
Get the code on your machine:
```
cd %userprofile%
git clone https://github.com/KA-Advocates/google-api-automation.git
```

Install the needed gems:
```
cd google-api-automation
bundle install
```

Make sure your Google Speadsheet has the following columns in this order:

* Title + Link - Title and Link to YT video
* YT link - Link to the ENG YT video
* YT ID - The ID of the ENG YT video
* Заглавие бг, предложено от експерт - Title for the video
* ОПИСАНИЕ НА ВИДЕО - Description of the video
* ОПИСАНИЕ НА КУРСА - Description of the course
* МАРКЕРИ - Tags
* Новогенериран YT Link - Newly generated YT Link

You can change the names of the columns - that doesn't affect the script. If you change the order of the columns, make sure to change the `config/settings.yaml` file accordingly.

Make sure that the names of the videos in your Google Drive are the same as their corresponding YT IDs in the Google Sreadsheet file you have. The script is going to try to upload only the videos that are not already uploaded to Youtube (by cheking for each row in the Google Speadsheet if it has the newly generated Youtube ID column (column H) empty). The script downloads the videos from Google Drive on your computer in a folder `video_transit_dir` inside of your `google-api-automation` folder. You can empty this folder occasionaly to clear space on your machine since once uploaded the videos are no longer needed there. Videos already downloaded from Google Drive and videos already uploaded (videos that have the newly generated Youtube ID column populated) are not downloaded again when the script is run again.

Go to the `config/settings.yaml` file in your `google-api-automation` folder and change `last_row` to be equal to the number of rows you have in your Google Speadsheet. Change `global_privacy` to be public or private according to your needs. Feel free to change any other settings if you need to.

* **tmp\_video\_download\_path:** "/google-api-automation/video_transit_dir/"
  <br>`Relative Path to where the videos will be downloaded before being uploaded`
* **global\_privacy:** "public"
  <br>`Scope of the playlists and videos inserted on youtube (public or private)`
* **youtube\_base\_url:** "https://youtu.be/"
  <br>`Base URL for the youtube videos`
* **khan\_youtube\_id:** "UCHNKwF_1cac1ebnOtrdXwVw"
  <br>`You can extract youtube channel id by going to your Khan channel and copying last part of the url.`
* **gdoc\_sheet\_url:**       
  "https://docs.google.com/spreadsheets/d/1WE3ba2vsrJLaVs_0ih6GEUz6hozTyEvKr1VJs023KsY/edit#gid=0"
  <br>`Just open the google doc spreadsheet with the right sheet and copy its URL.`
* **title\_col:** "D"
  <br>`Translated Youtube video title`
* **description\_col:** "E"
  <br>`Translated Youtube video description`
* **course\_description\_col:** "F"
  <br>`Translated Youtube video course description`
* **markers\_col:** "G"
  <br>`Markers/Tags`
* **eng\_video\_id:** "C"
  <br>`ENG Youtube video id`
* **ka\_youtube\_url\_col:** "H"
  <br>`Newly created Youtube video id`
* **sheet\_name:** "Sheet1"
  <br>`Sheet name in the google doc spreadsheet`
* **range\_starting\_col:** "A"
  <br>`First column of the sheet (needs to be first)`
* **first\_row:** 2
  <br>`First row of the sheet (assuming first one is for labels, put 2 here)`
* **range\_ending\_col:** "H"
  <br>`Put last column letter here so the needed data is included in the range`
* **last\_row:** 4
  <br>`Row number of the last non-empty row of the sheet`

## Running Script
  Assuming that you have read project *README*, run script (preferably using the *Start Command Prompt with Ruby* console):
  ```
  ruby %userprofile%/google-api-automation/src/main.rb
  ```   

## License
This project is licensed under the GNU GENERAL PUBLIC License - see the [LICENSE](LICENSE) file for details.
