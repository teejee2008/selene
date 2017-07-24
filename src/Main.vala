/*
 * Main.vala
 *
 * Copyright 2016 Tony George <teejee2008@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using GLib;
using Gtk;
using Gee;
using Json;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public Main App;
public const string AppName = "Selene Media Converter";
public const string AppShortName = "selene";
public const string AppVersion = "17.4.2";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";

const string GETTEXT_PACKAGE = "selene";
const string LOCALE_DIR = "/usr/share/locale";

extern void exit(int exit_code);

public enum FileStatus{
	PENDING,
	RUNNING,
	PAUSED,
	DONE,
	SKIPPED,
	SUCCESS,
	ERROR
}

public enum AppStatus{
	NOTSTARTED, //initial state
	RUNNING,
	PAUSED,
	IDLE,		//batch completed
	WAITFILE    //waiting for files
}

public class Main : GLib.Object{
	public Gee.ArrayList<MediaFile> InputFiles;
	public Gee.HashMap<string,Encoder> Encoders;
	public Gee.HashMap<string,FFmpegCodec> FFmpegCodecs;

	public string ScriptsFolder_Official = "";
	public string ScriptsFolder_Custom = "";
	public string PresetsFolder_Official = "";
	public string PresetsFolder_Custom = "";
	public string SharedImagesFolder = "";
	public string UserDataDirectory;
	public string SharedDataDirectory;
	public string AppConfPath = "";
	public string usr_share_dir;

	public string TempDirectory;
	public string OutputDirectory = "";
	public string BackupDirectory = "";
	public string InputDirectory = "";
	public bool TileView = true;
	
	public string PrimaryEncoder = "ffmpeg";
	public string PrimaryPlayer = "mpv";
	public string DefaultLanguage = "en";
	public bool DeleteTempFiles = true;

	public ScriptFile SelectedScript;
	public MediaFile CurrentFile;
	public string CurrentLine;
	public string StatusLine;
	public double Progress;

	//used by SimpleProgressWindow
	public string status_line = "";
	public int progress_total = 0;
	public int progress_count = 0;
	
	public bool BatchStarted = false;
	public bool BatchCompleted = false;
	public bool Aborted;

	public bool LowPriority = false;
	public AppStatus Status = AppStatus.NOTSTARTED;
	public bool ConsoleMode = false;
	public bool DebugMode = false;
	public bool Shutdown = false;
	public bool AdminMode = false;
	public bool BackgroundMode = false;
	public bool WaitingForShutdown = false;
	public bool ShowNotificationPopups = false;

	private Regex regex_generic;
	private Regex regex_mkvmerge;
	private Regex regex_libav;
	private Regex regex_libav_video;
	private Regex regex_libav_audio;
	private Regex regex_x264;
	private Regex regex_ffmpeg2theora;
	private Regex regex_ffmpeg2theora2;
	private Regex regex_ffmpeg2theora3;
	private Regex regex_opus;
	private Regex regex_vpxenc;
	private Regex regex_neroaacenc;

	public static string REQUIRED_COLUMNS = "name,spacer";
	public static string REQUIRED_COLUMNS_END = "spacer";
	public static string DEFAULT_COLUMNS = "name,size,duration,spacer";
	//public static string DEFAULT_COLUMNS_TILE_VIEW = "name,progress,spacer";
	public static string DEFAULT_COLUMN_ORDER = "name,size,duration,format,aformat,vformat,channels,samplingrate,width,height,framerate,bitrate,abitrate,vbitrate,artist,album,genre,title,tracknum,comments,recordeddate,progress,spacer";
	public string selected_columns = DEFAULT_COLUMNS;

	private string tempLine;
	private MatchInfo match;
	private double dblVal;
	private uint shutdownTimerID;
	private Pid procID;
	private string errLine = "";
	private string outLine = "";
	private DataInputStream disOut;
	private DataInputStream disErr;
	private DataOutputStream dsLog;

	Pid child_pid;
	int input_fd;
	int output_fd;
	int error_fd;
		
	private string blankLine = "";

	public static int main (string[] args) {
		//set locale
		//set_locale("");
		Intl.setlocale(GLib.LocaleCategory.ALL, "");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);

		//show help
		if (args.length > 1) {
			switch (args[1].down()) {
				case "--help":
				case "-h":
					stdout.printf (Main.help_message());
					return 0;
			}
		}

		stdout.printf("\n"); // print an empty line, otherwise log_debug() stops working; TODO: investigate

		//init GTK
		Gtk.init (ref args);

		//init TMP
		init_tmp();

		//init app
		App = new Main(args[0]);

	    //check if terminal supports colors
		string term = Environment.get_variable ("TERM").down();
		LOG_COLORS = (term == "xterm");

		log_debug("Parsing arguments...");
		
		//get command line arguments
		for (int k = 1; k < args.length; k++) // Oth arg is app path
		{
			switch (args[k].down()){
				case "--script":
					k++;
					if (k < args.length){
						App.SelectedScript = new ScriptFile(args[k]);
					}
					break;

				case "--output-dir":
					k++;
					if (k < args.length){
						if (args[k]=="none"){
							App.OutputDirectory = "";
						}
						else if (dir_exists (args[k])){
							App.OutputDirectory = args[k];
						}
					}
					break;

				case "--backup-dir":
					k++;
					if (k < args.length){
						if (args[k]=="none"){
							App.BackupDirectory = "";
						}
						else if (dir_exists (args[k])){
							App.BackupDirectory = args[k];
						}
					}
					break;

				case "--console":
					App.ConsoleMode = true;
					break;

				case "--debug":
					App.DebugMode = true;
					LOG_DEBUG = true;
					break;

				case "--shutdown":
					if (App.AdminMode) {
						App.Shutdown = true;
						log_msg (_("System will be shutdown after completion"));
					}
					else {
						log_error (_("Warning: User does not have Admin priviledges. '--shutdown' will be ignored."));
					}
					break;

				case "--background":
					App.BackgroundMode = true;
					App.set_priority();
					break;

				default:
					App.add_file (resolve_relative_path(args[k]));
					break;
			}
		}

		//check UI mode
		if ((App.SelectedScript == null)||(App.InputFiles.size == 0))
			App.ConsoleMode = false;

		LanguageCodes.build_maps();
		
		//show window
		if (App.ConsoleMode){
			if (App.InputFiles.size == 0){
				log_error (_("Input queue is empty! Please select files to convert."));
				return 1;
			}
			App.start_input_thread();
			App.convert_begin();
		}
		else{
			log_debug("Creating MainWindow\n");
			var window = new MainWindow();
			window.destroy.connect (App.exit_app);
			window.show_all();
		}
		
	    Gtk.main();

	    return 0;
	}

	public static string help_message(){
		string msg = "\n" + AppName + " v" + AppVersion + " by Tony George (teejee2008@gmail.com)" + "\n";
		msg += Environment.get_prgname() + " [options] <input-file-list>";
		msg +=
"""
Options:

  --script <string>      Select script file

  --output-dir <string>  Set output directory
                           'none' - Save files in input location

  --backup-dir <string>  Set backup directory
                           'none' - Do not move files

  --console              Console mode - GUI will not be loaded

  --shutdown             Shutdown system after completion (disabled by default)

  --background           Run with low priority (recommended)

  --debug                Show additional information

  --help                 List all options

Notes:

  1) The '--console' option is used for automated encoding.
     Script should be selected using the '--script' option and input files
     must be specified on the command line. Conversion will start immediately.

  2) Default settings will be used if an option is not specified. Default
     settings can be customized using the 'Settings' button in the main window.

  3) '--shutdown' requires Admin priviledges (use 'sudo')

  4) '--background' option will run all processes with lower priority. This
     allows the user to continue with other tasks while files are converted
     in the background.

  5) Running the app as Admin (using 'sudo') will enable some extra GUI options.
""";
		return msg;
	}

	public static void set_numeric_locale(string type){
		Intl.setlocale(GLib.LocaleCategory.NUMERIC, type);
	    Intl.setlocale(GLib.LocaleCategory.COLLATE, type);
	    Intl.setlocale(GLib.LocaleCategory.TIME, type);
	}
	
	
	public Main(string arg0){

		log_debug("Main()");
		
		InputFiles = new Gee.ArrayList<MediaFile>();
		Encoders = new Gee.HashMap<string,Encoder>();

		//check encoders
		init_encoder_list();
		check_all_encoders();
		check_and_default_av_encoder();
		check_ffmpeg_codec_support();

		//check critical encoders -------------------------
		
		string msg = "";
		if (!Encoders["mediainfo"].IsAvailable){
			msg += "%s ".printf("mediainfo");
		}
		if (!Encoders["ffmpeg"].IsAvailable && !Encoders["avconv"].IsAvailable){
			msg += "%s ".printf("ffmpeg avconv");
		}
		if (msg.length > 0){
			msg = _("Following utilities are not installed on your system:") + "\n\n%s\n\n".printf(msg) + _("Not possible to continue!");
			gtk_messagebox(_("Missing Utilities"), msg, null, true);
			exit(1);
		}
		
		// check for admin priviledges
		AdminMode = user_is_admin();

		// check for notify-send
		string path = get_cmd_path ("notify-send");
		if ((path != null)&&(path != "")){
			ShowNotificationPopups = true;
		}

		// set default directory paths
		string homeDir = Environment.get_home_dir();
		TempDirectory = Environment.get_tmp_dir() + "/" + Environment.get_prgname();
		create_dir (TempDirectory);
		OutputDirectory = "";
		BackupDirectory = "";

		usr_share_dir = "/usr/share";
		SharedDataDirectory = "/usr/share/selene";
		UserDataDirectory = homeDir + "/.config/selene";
		//string appPath = (File.new_for_path (arg0)).get_parent().get_path();

		ScriptsFolder_Official = SharedDataDirectory + "/scripts";
		ScriptsFolder_Custom = UserDataDirectory + "/scripts";
		PresetsFolder_Official = SharedDataDirectory + "/presets";
		PresetsFolder_Custom = UserDataDirectory + "/presets";
		SharedImagesFolder = SharedDataDirectory + "/images";

		AppConfPath = UserDataDirectory + "/selene.json";

		create_dir (UserDataDirectory);
		create_dir (ScriptsFolder_Custom);
		create_dir (PresetsFolder_Custom);

		// create a copy of official scripts & presets on first run

		if (dir_exists (ScriptsFolder_Official)){
			rsync(ScriptsFolder_Official, ScriptsFolder_Custom, false, false);
			rsync(PresetsFolder_Official, PresetsFolder_Custom, false, false);
		}

		// additional info

		log_msg (_("Loading scripts from:") + " '%s'".printf(ScriptsFolder_Custom));
		log_msg (_("Loading presets from:") + " '%s'".printf(PresetsFolder_Custom));
		log_msg (_("Using temp folder:") + " '%s'".printf(TempDirectory));

		// init config

		load_config();

		// init regular expressions

		try{
			regex_generic = new Regex("""([0-9.]+)%""");
			regex_mkvmerge = new Regex("""Progress: ([0-9.]+)%""");

			regex_libav = new Regex("""time=[ ]*([0-9:.]+)""");

			//frame=   82 fps= 23 q=28.0 size=     133kB time=1.42 bitrate= 766.9kbits/s
			regex_libav_video = new Regex("""frame=[ ]*[0-9]+ fps=[ ]*([0-9]+)[.]?[0-9]* q=[ ]*[0-9]+[.]?[0-9]* size=[ ]*([0-9]+)kB time=[ ]*[0-9:.]+ bitrate=[ ]*([0-9.]+)""");

			//size=    1590kB time=30.62 bitrate= 425.3kbits/s
			regex_libav_audio = new Regex("""size=[ ]*([0-9]+)kB time=[ ]*[0-9:.]+ bitrate=[ ]*([0-9.]+)""");

			//531 frames: 72.90 fps, 1509.18 kb/s
			regex_x264 = new Regex("""[ ]*([0-9]+) frames:[ ]*([0-9.]+) fps,[ ]*([0-9.]+) kb/s""");

			//  0:00:00.66 audio: 57kbps video: 404kbps, time elapsed: 00:00:00
			regex_ffmpeg2theora = new Regex ("""([0-9:.]+)[ ]*audio:[ ]*([0-9]+)kbps[ ]*video:[ ]*([0-9]+)kbps""");
			// 0:00:00.92 audio: 98kbps video: 87kbps, ET: 00:00:10, est. size: 0.2 MB
			regex_ffmpeg2theora2 = new Regex ("""([0-9:.]+)[ ]*audio:[ ]*([0-9]+)kbps[ ]*video:[ ]*([0-9]+)kbps,[ ]*ET:[ ]*([0-9:.]+),[ ]*est. size:[ ]*([0-9.]+)""");
			//Scanning first pass pos: 0:00:00.00 ET: 00:00:00
			regex_ffmpeg2theora3 = new Regex ("""Scanning first pass pos:[ ]*([0-9:.]+)[ ]*ET:[ ]*([0-9:.]+)""");

			//[/] 00:00:28.21 16.3x realtime, 60.68kbit/s
			//[-] 00:01:48.09   16x realtime,  60.7kbit/s
			regex_opus = new Regex ("""\[.\][ ]*([0-9:.]+)[ ]*([0-9]+)[.]?[0-9]*x realtime,[ ]*([0-9]+)[.]?[0-9]*kbit/s""");

			//Pass 1/1 frame    2/1       6755B
			regex_vpxenc = new Regex ("""(Pass[ ]*[0-9]+/[0-9]+)[ ]*frame[ ]*([0-9]+)/[0-9]+[ ]*([0-9]+)B""");

			//Processed 100 seconds...
			regex_neroaacenc = new Regex("""Processed[ ]*([0-9.]+)[ ]*seconds""");
		}
		catch (Error e) {
			log_error (e.message);
		}

		blankLine = "";
		for (int i=0; i<80; i++)
			blankLine += " ";

		log_debug("Main(): exit");
	}

	public void init_encoder_list(){
		
		Encoders["avconv"] = new Encoder("avconv","Libav Encoder","Audio-Video Decoding");
		Encoders["ffmpeg"] = new Encoder("ffmpeg","FFmpeg Encoder","Audio-Video Decoding");
		//Encoders["ffmpeg2theora"] = new Encoder("ffmpeg2theora","Theora Video Encoder","Theora Output");
		Encoders["lame"] = new Encoder("lame","LAME MP3 Encoder", "MP3 Output");
		Encoders["mediainfo"] = new Encoder("mediainfo","Media Information Utility","Reading Audio Video Properties");
		Encoders["mkvmerge"] = new Encoder("mkvmerge","Matroska Muxer","MKV Output");
		Encoders["mp4box"] = new Encoder("MP4Box","MP4 Muxer","MP4 Output");
		Encoders["neroaacenc"] = new Encoder("neroAacEnc","Nero AAC Audio Encoder","AAC/MP4 Output");
		Encoders["aacenc"] = new Encoder("aac-enc","Fraunhofer FDK AAC Encoder","AAC/MP4 Output");
		Encoders["oggenc"] = new Encoder("oggenc","OGG Audio Encoder","OGG Output");
		Encoders["opusenc"] = new Encoder("opusenc","Opus Audio Encoder","Opus Output");
		Encoders["sox"] = new Encoder("sox","SoX Audio Processing Utility","Sound Effects");
		Encoders["vpxenc"] = new Encoder("vpxenc","VP8 Video Encoder","VP8/WebM Output");
		Encoders["x264"] = new Encoder("x264","H.264 / MPEG-4 AVC Video Encoder","H264 Output");
		Encoders["x265"] = new Encoder("x265","H.265 / MPEG-H HEVC Video Encoder","H265 Output");
		Encoders["kateenc"] = new Encoder("kateenc","Kate Subtitle Encoder for OGG Files","Subtitles in OGG");
		Encoders["oggz"] = new Encoder("oggz","OGG Merge Tool","Merging OGG Files");

		//Encoders["ffplay"] = new Encoder("ffplay","FFmpeg's Audio Video Player","Audio-Video Playback");
		//Encoders["avplay"] = new Encoder("avplay","Libav's Audio Video Player","Audio-Video Playback");
		Encoders["mplayer"] = new Encoder("mplayer","Media Player","Audio-Video Playback");
		//Encoders["mplayer2"] = new Encoder("mplayer2","Media Player","Audio-Video Playback");
		Encoders["mpv"] = new Encoder("mpv","Media Player","Audio-Video Playback");
		//Encoders["smplayer"] = new Encoder("smplayer","Media Player","Audio-Video Playback");
		//Encoders["vlc"] = new Encoder("vlc","Media Player","Audio-Video Playback");
	}

	public void check_all_encoders(){
		foreach(Encoder enc in Encoders.values){
			enc.CheckAvailability();
		}
	}

	public void check_ffmpeg_codec_support(){
		FFmpegCodecs = FFmpegCodec.check_codec_support(PrimaryEncoder);
	}
	
	public void start_input_thread(){
		// start thread for reading user input

		try {
			Thread.create<void> (wait_for_user_input_thread, true);
		} catch (ThreadError e) {
			log_error (e.message);
		}
	}

	private void wait_for_user_input_thread(){
		while (true){  // loop runs for entire application lifetime
			wait_for_user_input();
		}
	}

	private void wait_for_user_input(){
		int ch = stdin.getc();

		if (WaitingForShutdown){
			Source.remove (shutdownTimerID);
			WaitingForShutdown = false;
			return;
		}
		else if ((ch == 'q')||(ch == 'Q')){
			if (Status == AppStatus.RUNNING){
				stop_batch();
			}
		}
		else if ((ch == 'p')||(ch == 'P')){
			if (Status == AppStatus.RUNNING){
				pause();
			}
		}
		else if ((ch == 'r')||(ch == 'R')){
			if (Status == AppStatus.PAUSED){
				resume();
			}
		}
	}

	public MediaFile? find_input_file (string filePath){
		foreach(MediaFile mf in InputFiles){
			if (mf.Path == filePath){
				return mf;
			}
		}

		return null;
	}

	public void save_config(){

		log_debug("save_config()");
		
		var config = new Json.Object();
		config.set_string_member("input-dir", InputDirectory);
		config.set_string_member("backup-dir", BackupDirectory);
		config.set_string_member("output-dir", OutputDirectory);
		config.set_string_member("last-script", SelectedScript.Path);
		config.set_string_member("tile-view", TileView.to_string());
		config.set_string_member("av-encoder", PrimaryEncoder);
		config.set_string_member("av-player", PrimaryPlayer);
		config.set_string_member("default-lang", DefaultLanguage);
		config.set_string_member("delete-temp-files", DeleteTempFiles.to_string());
		config.set_string_member("list-view-columns", selected_columns);
		
		if (SelectedScript != null) {
			config.set_string_member("last-script", SelectedScript.Path);
		} else {
			config.set_string_member("last-script", "");
		}

		var json = new Json.Generator();
		json.pretty = true;
		json.indent = 2;
		var node = new Json.Node(NodeType.OBJECT);
		node.set_object(config);
		json.set_root(node);

		try{
			json.to_file(AppConfPath);
		} catch (Error e) {
	        log_error (e.message);
	    }
	}

	public void load_config(){
		var f = File.new_for_path(AppConfPath);
		if (!f.query_exists()) { return; }

		log_debug("load_config()");

		var parser = new Json.Parser();
        try{
			parser.load_from_file(AppConfPath);
		} catch (Error e) {
	        log_error (e.message);
	    }
        var node = parser.get_root();
        var config = node.get_object();

		string val = json_get_string(config,"input-dir", InputDirectory);
		if (dir_exists(val))
			InputDirectory = val;
		else
			InputDirectory = "";

		val = json_get_string(config,"backup-dir", BackupDirectory);
		if (dir_exists(val))
			BackupDirectory = val;
		else
			BackupDirectory = "";

		val = json_get_string(config,"output-dir", OutputDirectory);
		if (dir_exists(val))
			OutputDirectory = val;
		else
			OutputDirectory = "";

		PrimaryEncoder = json_get_string(config,"av-encoder", "ffmpeg");
		PrimaryPlayer = json_get_string(config,"av-player", "mpv");
		DefaultLanguage = json_get_string(config,"default-lang", "en");

		DeleteTempFiles = json_get_bool(config,"delete-temp-files",true);

		check_and_default_av_encoder();
		check_and_default_av_player();

		val = json_get_string(config,"last-script", "");
		if (val != null && val.length > 0) {
			SelectedScript = new ScriptFile(val);
		}

		TileView = json_get_bool(config,"tile-view",true);

		selected_columns = json_get_string(config,"list-view-columns", selected_columns);

		log_debug("load_config(): exit");
	}

	public void check_and_default_av_encoder(){
		if (Encoders.has_key(PrimaryEncoder) && Encoders[PrimaryEncoder].IsAvailable){
			return;
		}
		
		if (Encoders["ffmpeg"].IsAvailable){
			PrimaryEncoder = "ffmpeg";
			return;
		}

		if (Encoders["avconv"].IsAvailable){
			PrimaryEncoder = "avconv";
			return;
		}
	}

	public void check_and_default_av_player(){
		if (Encoders.has_key(PrimaryPlayer) && Encoders[PrimaryPlayer].IsAvailable){
			return;
		}
		
		if (Encoders["mpv"].IsAvailable){
			PrimaryPlayer = "mpv";
			return;
		}

		if (Encoders["mplayer"].IsAvailable){
			PrimaryPlayer = "mplayer";
			return;
		}
	}
	
	public void exit_app(){
		log_debug("exit_app()");
		save_config();
		Gtk.main_quit();
	}

	public MediaFile? add_file (string filePath){
		MediaFile mFile = new MediaFile (filePath, App.PrimaryEncoder);

		if (mFile.IsValid
			&& mFile.Extension != ".srt"
			&& mFile.Extension != ".sub"
			&& mFile.Extension != ".idx"
			&& mFile.Extension != ".ssa"
			) {

			bool duplicate = false;
			foreach(MediaFile mf in InputFiles){
				if (mf.Path == mFile.Path){
					duplicate = true;
					break;
				}
			}

			if (duplicate)
			{
				return mFile; //not an error since file is already added
			}
			else{
				InputFiles.add(mFile);
				log_msg (_("File added:") + " '%s'".printf (mFile.Path));
				return mFile;
			}
		}
		else{
			log_error (_("Unknown format:") + " '%s'".printf (mFile.Path));
		}

		return null;
	}

	public void remove_files (Gee.ArrayList<MediaFile> file_list){
		foreach(MediaFile mf in file_list){
			InputFiles.remove (mf);
			log_msg (_("File removed:") + " '%s'".printf (mf.Path));
		}
	}

	public void remove_all(){
		InputFiles.clear();
		log_msg (_("All files removed"));
	}

	//conversion

	public void convert_begin(){
		//check for empty list
		if (InputFiles.size == 0){
			log_error (_("Input queue is empty! Please add some files."));
			return;
		}

		log_msg (_("Starting batch of %d file(s):").printf(InputFiles.size), true);

		//check and create output dir
		if (OutputDirectory.length > 0) {
			create_dir (OutputDirectory);
			log_msg (_("Files will be saved in '%s'").printf(OutputDirectory));
		}
		else{
			log_msg (_("Files will be saved in source directory"));
		}

		//check and create backup dir
		if (BackupDirectory.length > 0) {
			create_dir (BackupDirectory);
			log_msg (_("Source files will be moved to '%s'").printf(BackupDirectory));
		}

		//initialize batch control variables
		BatchStarted = true;
		BatchCompleted = false;
		Aborted = false;
		Status = AppStatus.RUNNING;

		//initialize file status
		foreach (MediaFile mf in InputFiles) {
			mf.Status = FileStatus.PENDING;
			mf.ProgressText = _("Queued");
			mf.ProgressPercent = 0;
		}

		//if(ConsoleMode)
			//progressTimerID = Timeout.add(500, update_progress);

		//save config and begin
		save_config();
		convert_next();
	}

	private void convert_next(){
		try {
			Thread.create<void>(convert_next_thread, true);
		} catch(ThreadError e) {
			log_error(e.message);
		}
	}

	private void convert_next_thread(){
		MediaFile nextFile = null;

		//find next pending file
		foreach (MediaFile mf in InputFiles) {
			if (mf.Status == FileStatus.PENDING){
				nextFile = mf;
				break;
			}
		}

		//encode the file
		if (!Aborted && nextFile != null){
			convert_file(nextFile);
			convert_next(); //check next
		}
		else{
			Status = AppStatus.IDLE;

			//handle shutdown for console mode
			if (ConsoleMode){
				if (Shutdown){
					log_msg (_("System will shutdown in one minute!"));
					log_msg (_("Enter any key to Cancel..."));
					shutdownTimerID = Timeout.add (60000, shutdown);
					WaitingForShutdown = true;
				}
				//exit app for console mode
				exit_app();
			}

			//shutdown will be handled by GUI window for GUI-mode
		}
	}

	public void convert_finish(){
		//reset file status
		foreach(MediaFile mf in InputFiles) {
			mf.Status = FileStatus.PENDING;
			mf.ProgressText = _("Queued");
			mf.ProgressPercent = 0;
		}

		//if (ConsoleMode)
			//Source.remove (progressTimerID);

		//reset batch control variables
		BatchStarted = true;
		BatchCompleted = true;
		Aborted = false;
		Status = AppStatus.NOTSTARTED;
	}

	private bool convert_file (MediaFile mf){
		bool is_success = false;

		if (file_exists (mf.Path) == false) {
			mf.Status = FileStatus.ERROR;
			mf.ProgressText = _("Error: File missing");
			mf.ProgressPercent = 0;
			return false;
		}

		//prepare file
		CurrentFile = mf;
		CurrentFile.prepare (TempDirectory);
		CurrentFile.Status = FileStatus.RUNNING;
		CurrentFile.ProgressText = null; // (not set) show value as percent
		CurrentFile.ProgressPercent = 0;

		log_msg (_("Source:") + " '%s'".printf(CurrentFile.Path), true);

		Progress = 0;
		StatusLine = "";
		CurrentLine = "";

		//convert file
		string scriptText = build_script (CurrentFile);
		string scriptPath = save_script (CurrentFile, scriptText);
		run_script (CurrentFile, scriptPath);
		is_success = check_status(CurrentFile);

		//move files to backup location on success
		if ((is_success == true) && (BackupDirectory.length > 0) && (dir_exists (BackupDirectory))){
			move_file (CurrentFile.Path, BackupDirectory + "/" + CurrentFile.Name);

			foreach(TextStream stream in mf.text_list){
				if (stream.IsExternal){
					move_file (stream.SubFile, BackupDirectory + "/" + stream.SubName);
				}
			}
		}

		return is_success;
	}

	private string build_script (MediaFile mf){
		var script = new StringBuilder();
		script.append ("#!/bin/bash\n");
		script.append ("\n");

		// insert variables -----------------

      	script.append ("tempDir='" + escape (mf.TempDirectory) + "'\n");
      	script.append ("inDir='" + escape (mf.Location) + "'\n");
      	if (OutputDirectory.length == 0){
      		script.append ("outDir='" + escape (mf.Location) + "'\n");
      	} else{
	      	script.append ("outDir='" + escape (OutputDirectory) + "'\n");
	    }
      	script.append ("logFile='" + escape (mf.LogFile) + "'\n");
      	script.append ("\n");
        script.append ("inFile='" + escape (mf.Path) + "'\n");
        script.append ("name='" + escape (mf.Name) + "'\n");
        script.append ("title='" + escape (mf.Title) + "'\n");
        script.append ("ext='" + escape (mf.Extension) + "'\n");
        script.append ("duration='" + escape ("%.0f".printf(mf.Duration / 1000)) + "'\n");
        script.append ("hasAudio=" + (mf.HasAudio ? "1" : "0") + "\n");
        script.append ("hasVideo=" + (mf.HasVideo ? "1" : "0") + "\n");
        script.append ("\n");

        if (mf.HasAudio){
			script.append ("tagTitle='" + escape(mf.TrackName) + "'\n");
			script.append ("tagTrackNum='" + escape(mf.TrackNumber) + "'\n");
			script.append ("tagArtist='" + escape(mf.Artist) + "'\n");
			script.append ("tagAlbum='" + escape(mf.Album) + "'\n");
			script.append ("tagGenre='" + escape(mf.Genre) + "'\n");
			script.append ("tagYear='" + escape(mf.RecordedDate) + "'\n");
			script.append ("tagComment='" + escape(mf.Comment) + "'\n");
			script.append ("\n");
		}

		script.append ("\n");
		script.append ("""scriptDir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"""");
		script.append ("\n");
		script.append ("cd \"$scriptDir\"\n");

		if (SelectedScript.Extension == ".sh") {

			// read and modify script template ---------------

			try {
				var fileScript = File.parse_name (SelectedScript.Path);
				var dis = new DataInputStream (fileScript.read());

				string line = dis.read_line (null);
				while (line != null) {
					line = line.replace ("${audiodec}", "%s -i \"${inFile}\" -f wav -acodec pcm_s16le -vn -y -".printf(PrimaryEncoder));

					script.append (line + "\n");
					line = dis.read_line (null);
				}
			} catch (Error e) {
				log_error (e.message);
			}
		}
		else if (SelectedScript.Extension == ".json") {
			var parser = new Json.Parser();
			try{
				parser.load_from_file(SelectedScript.Path);
			} catch (Error e) {
				log_error (e.message);
			}
			var node = parser.get_root();
			var config = node.get_object();

			script.append (get_preset_commandline (mf, config));

			//copy preset to temp folder for debugging
			copy_file(SelectedScript.Path, mf.TempDirectory + "/preset.json");
		}

		script.append ("exitCode=$?\n");
		script.append ("echo ${exitCode} > ${exitCode}\n");

		if (App.DeleteTempFiles){
			script.append ("\nif [ ${exitCode} -eq 0 ]; then\n");
			script.append ("\trm -rf video*\n");
			script.append ("\trm -rf audio*\n");
			script.append ("\trm -rf subs*\n");
			script.append ("fi\n\n");
		}

		return script.str;
	}

	private string escape (string txt){
		return txt.replace ("'","'\\''");
	}

	private string save_script (MediaFile mf, string scriptText){
		try{
			// create new script file
	        var file = File.new_for_path (mf.TempScriptFile);
	        var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			var data_stream = new DataOutputStream (file_stream);
	        data_stream.put_string (scriptText);
	        data_stream.close();

	        // set execute permission
	        chmod (mf.TempScriptFile, "u+x");
       	}
	    catch (Error e) {
	        log_error (e.message);
	        return "";
	    }

	    return mf.TempScriptFile;
	}

	private bool run_script (MediaFile mf, string scriptFile){
		bool retVal = true;

		if (ConsoleMode)
			log_msg (_("Converting: Enter (q) to quit or (p) to pause..."));
		else
			log_msg (_("Converting"));

		string[] spawn_args = new string[1];
		spawn_args[0] = scriptFile;
		
		string[] spawn_env = Environ.get ();
		
		try {

			//execute script file ---------------------

			Process.spawn_async_with_pipes(
			    TempDirectory, //working dir
			    spawn_args, //argv
			    spawn_env,  //environment
			    SpawnFlags.SEARCH_PATH,
			    null,   // child_setup
			    out child_pid,
			    out input_fd,
			    out output_fd,
			    out error_fd);

			procID = child_pid;

			set_priority();

			//create stream readers
			UnixInputStream uisOut = new UnixInputStream(output_fd, false);
			UnixInputStream uisErr = new UnixInputStream(error_fd, false);
			disOut = new DataInputStream(uisOut);
			disErr = new DataInputStream(uisErr);
			disOut.newline_type = DataStreamNewlineType.ANY;
			disErr.newline_type = DataStreamNewlineType.ANY;

			//create log file
	        var file = File.new_for_path (mf.LogFile);
	        var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			dsLog = new DataOutputStream (file_stream);

        	//start another thread for reading error stream

        	try {
			    Thread.create<void> (read_std_err, true);
		    } catch (Error e) {
		        log_error (e.message);
		    }

		    //start reading output stream in current thread
		    outLine = disOut.read_line (null);
		   	while (outLine != null) {
		        update_progress (outLine.strip());
		        outLine = disOut.read_line (null);
        	}

        	Thread.usleep ((ulong) 0.1 * 1000000);

        	dsLog.close();
			dsLog = null;
	
			disOut.close();
			disOut = null;
			GLib.FileUtils.close(output_fd);

			GLib.FileUtils.close(input_fd);
			
			Process.close_pid(child_pid); //required on Windows, doesn't do anything on Unix
		}
		catch (Error e) {
			log_error(e.message);
			retVal = false;
		}

        if (ConsoleMode){
	    	//remove the last status line
	    	stdout.printf ("\r%s\r", blankLine);
	    }

		return retVal;
	}

	private bool check_status (MediaFile mf){
		bool retVal = false;

		if (file_exists (mf.TempDirectory + "/0")) {
			mf.Status = FileStatus.SUCCESS;
			mf.ProgressText = _("Done");
			mf.ProgressPercent = 100;
			retVal = true;

			if (ShowNotificationPopups){
				notify_send (_("Completed"), mf.Name, 2000, "low");
			}
		}
		else{
			mf.Status = FileStatus.ERROR;
			mf.ProgressText = _("Error");
			mf.ProgressPercent = 0;
			retVal = false;

			if (ShowNotificationPopups){
				notify_send (_("Completed"), mf.Name, 2000, "low", "warning");
			}
		}

	    if (Aborted) {
	        log_msg (_("Stopped!"));
		}
		else if (mf.Status == FileStatus.SUCCESS) {
			log_msg (_("Completed"));
		}
		else if (mf.Status == FileStatus.ERROR) {
			log_msg (_("Failed"));
		}

		return retVal;
	}

	private void read_std_err(){
		try{
			errLine = disErr.read_line (null);
		    while (errLine != null) {
		        update_progress (errLine.strip());
		        errLine = disErr.read_line (null);
			}

			disErr.close();
			disErr = null;
			GLib.FileUtils.close(error_fd);
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	public bool update_progress (string line){
		tempLine = line;

		if ((tempLine == null)||(tempLine.length == 0)){ return true; }
		if (tempLine.index_of ("overread, skip") != -1){ return true; }
		if (tempLine.index_of ("Last message repeated") != -1){ return true; }
		if (tempLine.index_of ("Converting:") != -1){ return true; } //mkvmerge

		if (regex_libav.match (tempLine, 0, out match)){

			if (match.fetch(1).contains(":")){
				dblVal = parse_time(match.fetch(1));
			}
			else{
				dblVal = double.parse(match.fetch(1));
			}

			Progress = (dblVal * 1000) / CurrentFile.Duration;

			if (regex_libav_video.match (tempLine, 0, out match)){
				StatusLine = "(ffmpeg) %s fps, %s kbps, %s kb".printf(match.fetch(1), match.fetch(3), match.fetch(2));
			}
			else if (regex_libav_audio.match (tempLine, 0, out match)){
				StatusLine = "(ffmpeg) %s kbps, %s kb".printf(match.fetch(2), match.fetch(1));
			}
			else {
				StatusLine = tempLine;
			}
		}
		else if (regex_x264.match (tempLine, 0, out match)){
			dblVal = double.parse(match.fetch(1));
			Progress = dblVal / CurrentFile.OutputFrameCount;

			StatusLine = "%s fps, %s kbps".printf(match.fetch(2), match.fetch(3));
		}
		else if (regex_ffmpeg2theora.match (tempLine, 0, out match)){
			dblVal = parse_time (match.fetch(1));
			Progress = (dblVal * 1000) / CurrentFile.Duration;

			if (regex_ffmpeg2theora2.match (tempLine, 0, out match)){
				StatusLine = "(ffmpeg2theora) %s+%s kbps, %s mb, eta %s".printf(match.fetch(2), match.fetch(3), match.fetch(5), match.fetch(4));
			}
			else {
				StatusLine = "(ffmpeg2theora) %s+%s kbps".printf(match.fetch(2), match.fetch(3));
			}
		}
		else if (regex_ffmpeg2theora3.match (tempLine, 0, out match)){
			dblVal = parse_time (match.fetch(1));
			Progress = (dblVal * 1000) / CurrentFile.Duration;
			StatusLine = "(ffmpeg2theora) Scanning first pass, eta %s".printf(match.fetch(2));
		}
		else if (regex_opus.match (tempLine, 0, out match)){
			dblVal = parse_time (match.fetch(1));
			Progress = (dblVal * 1000) / CurrentFile.Duration;
			StatusLine = "(opusenc) %sx, %s kbps".printf(match.fetch(2), match.fetch(3));
		}
		else if (regex_vpxenc.match (tempLine, 0, out match)){
			dblVal = double.parse(match.fetch(2));
			Progress = dblVal / CurrentFile.OutputFrameCount;
			StatusLine = "(vpxenc) %s, %s frames, %.0f kb".printf(match.fetch(1), match.fetch(2), double.parse(match.fetch(3))/1000);
		}
		else if (regex_neroaacenc.match (tempLine, 0, out match)){
			dblVal = double.parse(match.fetch(1));
			Progress = (dblVal * 1000) / CurrentFile.Duration;
			StatusLine = tempLine;
		}
		else if (regex_generic.match (tempLine, 0, out match)){
			dblVal = double.parse(match.fetch(1));
			Progress = dblVal / 100;

			if (regex_mkvmerge.match (tempLine, 0, out match)){
				StatusLine = "(mkvmerge) %.0f %%".printf(Progress * 100);
			}
			else if (regex_x264.match (tempLine, 0, out match)){
				StatusLine = "(x264) %s fps, %s kbps, eta %s".printf(match.fetch(1),match.fetch(2),match.fetch(3));
			}
			else {
				StatusLine = tempLine;
			}
		}
		else {
			StatusLine = tempLine;
			try{
				dsLog.put_string (tempLine + "\n");
			}
			catch (Error e) {
				log_error (e.message);
			}
		}

		if (Progress < 1) {
			CurrentFile.ProgressPercent = (int)(Progress * 100);
		}
		else{
			CurrentFile.ProgressPercent = 100;
		}

		if (ConsoleMode){
			stdout.printf ("\r%s\r", blankLine[0:78]);
			if (Status == AppStatus.RUNNING){
				if (StatusLine.length > 70)
					stdout.printf ("\r[%3.0f%%] %-72s", (Progress*100), StatusLine[0:70]);
				else
					stdout.printf ("\r[%3.0f%%] %-72s", (Progress*100), StatusLine);
			}
			stdout.flush();
		}

		return true;
	}

	public void stop_batch(){
		// we need to un-freeze the processes before we kill it
		if (Status == AppStatus.PAUSED){
			resume();
		}

		Aborted = true;
		for(int k = InputFiles.index_of(CurrentFile); k < InputFiles.size; k++)
		{
			MediaFile mf  = InputFiles[k];
			mf.ProgressText = _("Cancelled");
		}

	    process_kill (procID);
	}

	public void stop_file(){
		// we need to un-freeze the processes before we kill them
		if (Status == AppStatus.PAUSED){
			resume();
		}

		// Aborted = true; //Do not set Abort flag
		CurrentFile.Status = FileStatus.SKIPPED;
		CurrentFile.ProgressText = _("Cancelled");

	    process_kill (procID);
	}

	public void pause(){
		Pid childPid;
	    foreach (long pid in get_process_children (procID)){
		    childPid = (Pid) pid;
		    process_pause (childPid);
	    }

		Status = AppStatus.PAUSED;
		CurrentFile.ProgressText = _("Paused");

		if (ConsoleMode)
			log_msg (_("Paused: Enter (r) to resume..."));
		else
			log_msg (_("Paused"));
	}

	public void resume(){
		Pid childPid;
	    foreach (long pid in get_process_children (procID)){
		    childPid = (Pid) pid;
		    process_resume (childPid);
	    }

		Status = AppStatus.RUNNING;
		CurrentFile.ProgressText = null;

	    if (ConsoleMode)
			log_msg (_("Converting: Enter (q) to quit or (p) to pause..."));
		else
			log_msg (_("Converting") + "...");
	}

	public void set_priority(){
		int prio = 0;
		if (BackgroundMode) { prio = 5; }

		Pid appPid = Posix.getpid();
		process_set_priority (appPid, prio);

		if (Status == AppStatus.RUNNING){
			process_set_priority (procID, prio);

			Pid childPid;
			foreach (long pid in get_process_children (procID)){
				childPid = (Pid) pid;

				if (BackgroundMode)
					process_set_priority (childPid, prio);
				else
					process_set_priority (childPid, prio);
			}
		}
	}

	private bool shutdown(){
		shutdown();
		return true;
	}


	//create command string

	private string get_preset_commandline (MediaFile mf, Json.Object settings, out Gee.ArrayList<string>? encoderList = null){
		string s = "";

		//this list is used for returning the list of encoders used by the preset
		encoderList = new Gee.ArrayList<string>();

		Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");
		
		//set output file path ----------------
		
		string outpath = "";
		if (OutputDirectory.length == 0){
      		outpath = mf.Location;
      	} else{
	      	outpath = OutputDirectory;
	    }

		string suffix = "";
		int count = -1;
		
		do{
			count++;
			suffix = (count == 0) ? "" : " (%d)".printf(count);
			mf.OutputFilePath = "%s/%s%s%s".printf(outpath, mf.Title, suffix, general.get_string_member("extension"));
		}
		while (file_exists(mf.OutputFilePath));

		//insert temporary file names ------------
		
		s += "\n";

		//output file --------
		
		s += "outputFile=\"${outDir}/${title}" + suffix + general.get_string_member("extension") + "\"\n";

		//temp video -------------
		
		string tempVideoExt = ".mkv";
		if (mf.HasVideo && video.get_string_member("codec") != "disable"){
			switch (video.get_string_member("codec")) {
			case "copy":
				switch(mf.VideoFormat.down()){
				case "avc":
					tempVideoExt = ".mkv";
					break;
				case "hevc":
					tempVideoExt = ".m4v";
					break;
				case "vp8":
				case "vp9":
					tempVideoExt = ".webm";
					break;
				case "theora":
					tempVideoExt = ".ogv";
					break;
				default:
					tempVideoExt = ".mkv";
					break;
				}
				break;
			default:
				tempVideoExt = general.get_string_member("extension");
				break;
			}

			foreach(VideoStream stream in mf.video_list){
				if (!stream.IsSelected){
					continue;
				}
				s += "temp_video_%d=\"video-%d%s\"\n".printf(stream.TypeIndex,stream.TypeIndex,tempVideoExt);
			}
		}

		// temp audio ----------------
		
		string tempAudioExt = ".mka";
		if (mf.HasAudio && audio.get_string_member("codec") != "disable"){
			switch (audio.get_string_member("codec")) {
			case "mp3lame":
				tempAudioExt = ".mp3";
				break;
			case "aac":
			case "neroaac":
			case "libfdk_aac":
				tempAudioExt = ".m4a";
				break;
			case "vorbis":
				tempAudioExt = ".ogg";
				break;
			case "opus":
				tempAudioExt = ".opus";
				break;
			case "copy":
				//set temp file extension based on input audio format
				switch(mf.AudioFormat.down()){
				case "ac-3":
					tempAudioExt = ".ac3";
					break;
				case "flac":
					tempAudioExt = ".flac";
					break;
				case "pcm":
					tempAudioExt = ".wav";
					break;
				case "aac":
					tempAudioExt = ".m4a";
					break;
				case "vorbis":
					tempAudioExt = ".ogg";
					break;
				case "opus":
					tempAudioExt = ".opus";
					break;
				default:
					tempAudioExt = ".mka";
					break;
				}
				//NOTE: Use same contruct in copy_audio_avconv()
				break;
			default:
				tempAudioExt = ".mka";
				break;
			}

			foreach(AudioStream stream in mf.audio_list){
				if (!stream.IsSelected){
					continue;
				}
				s += "temp_audio_%d=\"audio-%d%s\"\n".printf(stream.TypeIndex,stream.TypeIndex,tempAudioExt);
			}
		}

		// temp subs ---------------

		if (mf.HasSubs && subs.get_string_member("mode") == "embed"){
			foreach(TextStream stream in mf.text_list){
				if (!stream.IsSelected){
					//log_msg("%d:not-selected".printf(stream.TypeIndex));
					continue;
				}
				s += "temp_subs_%d=\"subs-%d%s\"\n".printf(stream.TypeIndex,stream.TypeIndex,".srt");
			}
		}
		
		s += "\n";

		//create command line --------------

		string format = general.get_string_member("format");
		string acodec = audio.get_string_member("codec");
		string vcodec = video.get_string_member("codec");
		string submode = subs.get_string_member("mode");

		switch (format){
		case "mkv":
		case "mp4v":
		case "webm":
		case "ogv":
			foreach(VideoStream stream in mf.video_list){
				if (!stream.IsSelected){
					continue;
				}
				
				//encode video
				switch (vcodec){
				case "x264":
				case "x265":
					s += encode_video_x264(mf,stream,settings);
					encoderList.add(vcodec);
					break;
				case "vp8":
				case "vp9":
				case "theora":
					s += encode_video_avconv(mf,stream,settings);
					encoderList.add(PrimaryEncoder);
					break;
				case "copy":
					s += copy_video_avconv(mf,stream,settings);
					encoderList.add(PrimaryEncoder);
					break;
				}
			}

			foreach(AudioStream stream in mf.audio_list){
				if (!stream.IsSelected){
					continue;
				}
				
				//encode audio
				if (mf.HasAudio && acodec != "disable") {
					switch (acodec) {
					case "mp3lame":
						s += encode_audio_mp3lame(mf,stream,settings);
						encoderList.add("lame");
						if (audio.get_boolean_member("soxEnabled")){
							encoderList.add("sox");
						};
						break;
					case "neroaac":
						s += encode_audio_neroaac(mf,stream,settings);
						encoderList.add("neroaacenc");
						if (audio.get_boolean_member("soxEnabled")){
							encoderList.add("sox");
						};
						break;
					case "aac":
						s += encode_audio_avconv(mf,stream,settings);
						encoderList.add(PrimaryEncoder);
						if (audio.get_boolean_member("soxEnabled")){
							encoderList.add("sox");
						};
						break;
					case "libfdk_aac":
						s += encode_audio_fdkaac(mf,stream,settings);
						encoderList.add("aacenc");
						if (audio.get_boolean_member("soxEnabled")){
							encoderList.add("sox");
						};
						break;
					case "vorbis":
						s += encode_audio_oggenc(mf,stream,settings);
						encoderList.add("oggenc");
						if (audio.get_boolean_member("soxEnabled")){
							encoderList.add("sox");
						};
						break;
					case "opus":
						s += encode_audio_opus(mf,stream,settings);
						encoderList.add("opusenc");
						if (audio.get_boolean_member("soxEnabled")){
							encoderList.add("sox");
						};
						break;
					case "copy":
						s += copy_audio_avconv(mf,stream,settings);
						encoderList.add(PrimaryEncoder);
						break;
					}
				}
			}

			foreach(TextStream stream in mf.text_list){
				if (!stream.IsSelected){
					continue;
				}
				
				//encode subs
				if (mf.HasSubs && (submode == "embed")) {
					s += encode_sub_avconv(mf,stream,settings);
					encoderList.add(PrimaryEncoder);
				}
			}

			//merge the subs encoded in previous step
			if (format == "ogv"){
				s += encode_sub_kateenc(mf,settings);
				encoderList.add("kateenc");
			}
			
			//mux audio, video and subs
			switch (format){
			case "mkv":
			case "webm":
				s += mux_mkvmerge(mf,settings);
				encoderList.add("mkvmerge");
				break;
			case "mp4v":
				switch (vcodec){
				case "x265":
					s += mux_avconv(mf,settings);
					encoderList.add(PrimaryEncoder);
					break;
				default:
					s += mux_mp4box(mf,settings);
					encoderList.add("mp4box");
					break;
				}
				break;
			case "ogv":
				s += mux_oggz(mf,settings);
				encoderList.add("oggz");
				break;
			}
			break;

		//case "ogv":
		//	s += encode_video_ffmpeg2theora(mf,settings);
		//	encoderList.add("ffmpeg2theora");
		//	break;

		case "mp3":
			foreach(AudioStream stream in mf.audio_list){
				if (!stream.IsSelected){
					continue;
				}
				s += encode_audio_mp3lame(mf,stream,settings);
				encoderList.add("lame");
				if (audio.get_boolean_member("soxEnabled")){
					encoderList.add("sox");
				};
			}
			break;

		case "mp4a":
			foreach(AudioStream stream in mf.audio_list){
				if (!stream.IsSelected){
					continue;
				}
				
				switch (acodec) {
				case "neroaac":		
					s += encode_audio_neroaac(mf,stream,settings);
					encoderList.add("neroaacenc");
					if (audio.get_boolean_member("soxEnabled")){
						encoderList.add("sox");
					};
					break;
					
				case "aac":
					s += encode_audio_avconv(mf,stream,settings);
					encoderList.add(PrimaryEncoder);
					if (audio.get_boolean_member("soxEnabled")){
						encoderList.add("sox");
					};
					break;
					
				case "libfdk_aac":	
					s += encode_audio_fdkaac(mf,stream,settings);
					encoderList.add("aacenc");
					if (audio.get_boolean_member("soxEnabled")){
						encoderList.add("sox");
					};
					break;
				}
			}
			break;
			
		case "opus":
			foreach(AudioStream stream in mf.audio_list){
				if (!stream.IsSelected){
					continue;
				}
				s += encode_audio_opus(mf,stream,settings);
				encoderList.add("opusenc");
				if (audio.get_boolean_member("soxEnabled")){
					encoderList.add("sox");
				};
			}
			break;

		case "ogg":
			foreach(AudioStream stream in mf.audio_list){
				if (!stream.IsSelected){
					continue;
				}
				s += encode_audio_oggenc(mf,stream,settings);
				encoderList.add("oggenc");
				if (audio.get_boolean_member("soxEnabled")){
					encoderList.add("sox");
				};
			}
			break;

		case "ac3":
		case "flac":
		case "wav":
			foreach(AudioStream stream in mf.audio_list){
				if (!stream.IsSelected){
					continue;
				}
				s += encode_audio_avconv(mf,stream,settings);
				encoderList.add(PrimaryEncoder);
				if (audio.get_boolean_member("soxEnabled")){
					encoderList.add("sox");
				};
			}
			break;
		}

		s += "\n";

		return s;
	}

	public Gee.ArrayList<string> get_encoder_list(){
		var encoderList = new Gee.ArrayList<string>();

		if (SelectedScript.Extension == ".json") {
			var parser = new Json.Parser();
			try{
				parser.load_from_file(SelectedScript.Path);
			} catch (Error e) {
				log_error (e.message);
			}
			var node = parser.get_root();
			var config = node.get_object();

			get_preset_commandline(InputFiles[0], config, out encoderList);
		}

		return encoderList;
	}

	//decode -----------------
	
	private string decode_video_avconv (MediaFile mf, VideoStream stream, Json.Object settings, bool silent, bool resample = true, bool crop = true, bool scale = true){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		//Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");
		//Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += PrimaryEncoder;

		//progress info
		if (silent){
			s += " -nostats";
		}

		//seek input
		if ((mf.StartPos > 0) && (mf.clip_list.size < 2)){
			s += " -ss %.1f".printf(mf.StartPos);
		}

		//input
		s += " -i \"${inFile}\"";

		//map stream
		s += " -map 0:v:%d".printf(stream.TypeIndex);
		
		//stop output
		if ((mf.EndPos > 0) && (mf.clip_list.size < 2)){
			s += " -to %.1f".printf(mf.EndPos - mf.StartPos);
		}

		//format
		s += " -copyinkf -f rawvideo -vcodec rawvideo -pix_fmt yuv420p";

		//avconv_filters (resample, crop, resize, trim)
		s += avconv_filters(mf,settings, true, false, resample, crop, scale);

		//output
		s += " -an -sn -y - | ";

		return s;
	}

	private string decode_audio_avconv(MediaFile mf, AudioStream stream, Json.Object settings, bool silent, string temp_file_name = ""){
		string s = "";

		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		string acodec = audio.get_string_member("codec");
		bool sox_enabled = audio.get_boolean_member("soxEnabled");

		s += PrimaryEncoder;

		//progress info
		if (silent){
			s += " -nostats";
		}
		else{
			s += " -stats";
		}

		//seek input
		if ((mf.StartPos > 0) && (mf.clip_list.size < 2)){
			s += " -ss %.1f".printf(mf.StartPos);
		}
		
		//input
		s += " -i \"${inFile}\"";

		//map stream
		s += " -map 0:a:%d".printf(stream.TypeIndex);

		//stop output
		if ((mf.EndPos > 0) && (mf.clip_list.size < 2)){
			s += " -to %.1f".printf(mf.EndPos - mf.StartPos);
		}

		//format
		s += " -f " + ((sox_enabled) ? "aiff" : "wav");
		s += " -acodec pcm_s16le";

		//channels
		string channels = audio.get_string_member("channels");
		if (channels == "disable"){
			if (acodec == "mp3lame" && mf.AudioChannels > 2){
				s += " -ac 2";
				log_msg ("Downmixing to stereo, LAME does not support more than 2 channels");
			}
		}
		else{
			s += " -ac " + channels;
		}

		//sampling
		string sampling = audio.get_string_member("samplingRate");
		if (sampling != "disable"){
			s += " -ar " + sampling;
		}

		//avconv_filters (trim)
		s += avconv_filters(mf,settings, false, true);

		//output
		s += " -vn";

		if (sox_enabled){
			s += " -y - | ";
			s += process_audio_sox(mf,settings,temp_file_name);
		}
		else{
			if (temp_file_name.length > 0){
				s += " -y '%s'".printf(temp_file_name);
				s += "\n";
			}
			else{
				s += " -y - | ";
			}
		}

		return s;
	}

	//copy -----------------
	
	private string copy_video_avconv (MediaFile mf, VideoStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		//Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		//Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += PrimaryEncoder;

		//progress info
		//if (silent){
		//	s += " -nostats";
		//}

		//seek input
		if ((mf.StartPos > 0) && (mf.clip_list.size < 2)){
			s += " -ss %.1f".printf(mf.StartPos);
		}

		//input
		s += " -i \"${inFile}\"";

		//map stream
		s += " -map 0:v:%d".printf(stream.TypeIndex);

		//stop output
		if ((mf.EndPos > 0) && (mf.clip_list.size < 2)){
			s += " -to %.1f".printf(mf.EndPos - mf.StartPos);
		}

		//format
		s += " -copyinkf";

		//format
		switch(mf.VideoFormat.down()){
			case "avc":
				s += " -f matroska";
				break;
			case "hevc":
				s += " -f mp4";
				break;
			case "vp8":
			case "vp9":
				s += " -f webm";
				break;
			case "theora":
				s += " -f ogv";
				break;
			default:
				s += " -f matroska";
				break;
		}
		//NOTE: Use same contruct in get_preset_commandline()
		
		//copy video
		s += " -vcodec copy";
		
		//output
		s += " -an -sn";

		//output
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			//encode to tempVideo
			s += " -y \"${temp_video_%d}\"".printf(stream.TypeIndex);
		}
		else {
			//encode to outputFile
			s += " -y \"${outputFile}\"";
		}

		s += "\n";
		
		return s;
	}

	private string copy_audio_avconv(MediaFile mf, AudioStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");
		//Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += PrimaryEncoder;

		//progress info
		//if (silent){
		//	s += " -nostats";
		//}

		//seek input
		if ((mf.StartPos > 0) && (mf.clip_list.size < 2)){
			s += " -ss %.1f".printf(mf.StartPos);
		}

		//input
		s += " -i \"${inFile}\"";

		//map stream
		s += " -map 0:a:%d".printf(stream.TypeIndex);

		//stop output
		if ((mf.EndPos > 0) && (mf.clip_list.size < 2)){
			s += " -to %.1f".printf(mf.EndPos - mf.StartPos);
		}

		//format
		switch(mf.AudioFormat.down()){
			case "ac-3":
				s += " -f ac3";
				break;
			case "flac":
				s += " -f flac";
				break;
			case "pcm":
				s += " -f wav";
				break;
			case "aac":
				s += " -f mp4";
				break;
			case "vorbis":
				s += " -f ogg";
				break;
			case "opus":
				s += " -f opus";
				break;
			default:
				s += " -f matroska";
				break;
		}
		//NOTE: Use same contruct in get_preset_commandline()
		
		//copy audio
		s += " -acodec copy";

		s += " -vn -sn";

		//output
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " -y \"${temp_audio_%d}\"".printf(stream.TypeIndex);
		}
		else {
			//encode to outputFile
			s += " -y \"${outputFile}\"";
		}

		s += "\n";
		
		return s;
	}

	// encode subs ---------------------
	
	private string encode_sub_avconv(MediaFile mf, TextStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		//Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");
		//Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += PrimaryEncoder;

		//progress info
		//if (silent){
		//	s += " -nostats";
		//}

		//seek input
		if ((mf.StartPos > 0) && (mf.clip_list.size < 2)){
			s += " -ss %.1f".printf(mf.StartPos);
		}

		if (stream.IsExternal){
			//character encoding - required for SRT files
			if (!stream.CharacterEncoding.up().contains("UNKNOWN")){
				s += " -sub_charenc \"%s\"".printf(stream.CharacterEncoding.up());
			}

			//input
			s += " -i \"%s\"".printf(stream.SubFile);
		}
		else{
			//input
			s += " -i \"${inFile}\"";

			//map stream
			s += " -map 0:s:%d".printf(stream.TypeIndex);
		}
		
		//stop output
		if ((mf.EndPos > 0) && (mf.clip_list.size < 2)){
			s += " -to %.1f".printf(mf.EndPos - mf.StartPos);
		}

		//format
		s += " -f srt";

		//copy audio
		s += " -scodec subrip";

		s += " -vn -an";

		s += " -y \"${temp_subs_%d}\"".printf(stream.TypeIndex); 
		
		//output
		//if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			
		//}
		//else {
		//	//encode to outputFile
		//	//s += " -y \"${outputFile}\"";
		//}

		s += "\n";
		
		return s;
	}

	private string encode_sub_kateenc(MediaFile mf, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		if (mf.HasSubs && subs.get_string_member("mode") == "embed"){
			foreach(TextStream stream in mf.text_list){
				if (stream.IsSelected){
					s += "kateenc -t srt ";

					if (mf.HasVideo && video.get_string_member("codec") != "disable"){
						s += " -c SUB";
					}
					else if (mf.HasAudio && audio.get_string_member("codec") != "disable"){
						s += " -c LRC";
					}
					
					s += " -o \"subs_kate_%d.ogg\"".printf(stream.TypeIndex);
					if (stream.LangCode.length > 0){
						s += " -l %s".printf(stream.LangCode);
					}
					s += " \"${temp_subs_%d}\"".printf(stream.TypeIndex);
					s += "\n";
				}
			}
		}

		return s;
	}

	//encode video -------------------
	
	private string encode_video_avconv (MediaFile mf, VideoStream stream, Json.Object settings){
		string s = "";

		Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");
		string vcodec = video.get_string_member("codec");
		string format = general.get_string_member("format");

		s += PrimaryEncoder;

		//seek input
		if ((mf.StartPos > 0) && (mf.clip_list.size < 2)){
			s += " -ss %.1f".printf(mf.StartPos);
		}
		
		s += " -i \"${inFile}\"";

		//map stream
		s += " -map 0:v:%d".printf(stream.TypeIndex);

		//stop output
		if ((mf.EndPos > 0) && (mf.clip_list.size < 2)){
			s += " -to %.1f".printf(mf.EndPos - mf.StartPos);
		}

		if (format == "ogv"){
			s += " -f ogg";
		}
		else{
			s += " -f " + format;
		}

		switch(vcodec){
			case "vp8":
			s	 += " -c:v libvpx";
				break;
			case "vp9":
				s += " -c:v libvpx-" + vcodec;
				break;
			case "theora":
				s += " -c:v lib" + vcodec;
				break;
		}

		if (video.get_string_member("mode") == "2pass"){
			s += " -pass {passNumber}";
		}

		switch(vcodec){
		case "vp8":
		case "vp9":
			switch(video.get_string_member("mode")){
			case "vbr":
			case "2pass":
				string bitrate = video.get_string_member("bitrate");
				s += " -b:v " + bitrate + "k";
				break;
			case "cbr":
				string bitrate = video.get_string_member("bitrate");
				s += " -b:v " + bitrate + "k";
				s += " -minrate " + bitrate + "k";
				s += " -maxrate " + bitrate + "k";
				break;
			case "cq":
				string vquality = "%.0f".printf(double.parse(video.get_string_member("quality")));
				s += " -crf " + vquality;
				s += " -qmin " + vquality;
				s += " -qmax " + vquality;
				break;
			}
			break;
		case "theora":
			switch(video.get_string_member("mode")){
			case "abr":
			case "2pass":
				string bitrate = video.get_string_member("bitrate");
				s += " -b:v " + bitrate + "k";
				break;
			case "vbr":
				string vquality = "%.0f".printf(double.parse(video.get_string_member("quality")));
				s += " -q:v " + vquality;
				break;
			}
			break;
		}

		switch(vcodec){
			case "vp8":
			case "vp9":
				if (video.has_member("vpx_deadline")){
					s += " -deadline " + video.get_string_member("vpx_deadline");
				}
				else{
					s += " -deadline good";
				}
				if (video.has_member("vpx_speed")){
					s += " -cpu-used " + video.get_string_member("vpx_speed");
				}
				else{
					s += " -cpu-used 1";
				}
				break;
		}

		//---------------

		//user options
		if (video.get_string_member("options").strip() != "") {
			s += " " +  video.get_string_member("options").strip();
		}

		//avconv_filters (resample, crop, resize, trim)
		s += avconv_filters(mf,settings,true,false);

		//disable audio and subs
		s += " -an -sn";

		//output
		s += " -y {outputFile}"; //no quotes

		s += "\n";

		if (video.get_string_member("mode") == "2pass"){
			string temp = s.replace("{passNumber}","1").replace("{outputFile}","/dev/null");
			temp += s.replace("{passNumber}","2").replace("{outputFile}","\"${temp_video_%d}\"".printf(stream.TypeIndex));
			s = temp;
		}
		else{
			s = s.replace("{outputFile}","\"${temp_video_%d}\"".printf(stream.TypeIndex));
		}

		return s;
	}

	private string encode_video_x264 (MediaFile mf, VideoStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");
		string vcodec = video.get_string_member("codec");

		bool usePiping = true;

		/* Note: If x264 is compiled without lavf or ffms support then
		 * piping is required. Since this is the most common case,
		 * we will always use piping to ensure that encoding does not fail.
		 * */

		if (usePiping) {
			s += decode_video_avconv(mf,stream,settings,true,true,false,false);

			/* Note:
			 * Resampling with be done by ffmpeg since x264 does not provide this option.
			 * Cropping and scaling will be done by x264 since it provides extra options such as resizing method.
			 * */
		}

		switch(vcodec){
			case "x264":
				s += "x264";
				break;
			case "x265":
				s += "x265";
				break;
		}


		if (video.get_string_member("mode") == "2pass"){
			s += " --pass {passNumber}";
		}

		s += " --preset " + video.get_string_member("preset");

		if (video.get_string_member("profile").length > 0){
			s += " --profile " + video.get_string_member("profile");
		}

		switch(video.get_string_member("mode")){
			case "vbr":
				s += " --crf " + video.get_string_member("quality");
				break;
			case "abr":
			case "2pass":
				s += " --bitrate " + video.get_string_member("bitrate");
				break;
		}

		// filters ----------

		string vf = "";

		//cropping
		if (mf.crop_enabled()) {
			vf += "/crop:" + mf.crop_values_x264();
		}

		//resizing
		int w,h;
		bool rescale = calculate_video_resolution(mf, settings, out w, out h);
		if (rescale) {
			string method = video.get_string_member("resizingMethod");
			vf += "/resize:width=%d,height=%d,method=%s".printf(w,h,method);
		}

		if (vf.length > 0){
			s += " --vf " + vf[1:vf.length];
		}

		//other options
		if (video.get_string_member("options").strip() != "") {
			s += " " +  video.get_string_member("options").strip();
		}

		//add output file path placeholder
		s += " -o {outputFile}";

		/* Note: For x264, output is always written to tempVideo and then muxed into outputFile */

		if (usePiping) {
			//encode from stdin
			s += " -";

			//specify source dimensions
			s += " --input-res %dx%d".printf(mf.SourceWidth, mf.SourceHeight);

			//specify source FPS
			int fpsNum = int.parse(video.get_string_member("fpsNum"));
			int fpsDenom = int.parse(video.get_string_member("fpsDenom"));
			if (fpsNum != 0 && fpsDenom != 0) {
				s += " --fps %d/%d".printf(fpsNum, fpsDenom);
			}
			else{
				s += " --fps %.0lf/1000".printf(mf.SourceFrameRate * 1000);
			}

		}
		else {
			//encode from input file
			s += " \"${inFile}\"";
		}

		s += "\n";

		if (video.get_string_member("mode") == "2pass"){
			string temp = s.replace("{passNumber}","1").replace("{outputFile}","/dev/null");
			temp += s.replace("{passNumber}","2").replace("{outputFile}","\"${temp_video_%d}\"".printf(stream.TypeIndex));
			s = temp;
		}
		else{
			s = s.replace("{outputFile}","\"${temp_video_%d}\"".printf(stream.TypeIndex));
		}

		return s;
	}

	/*private string encode_video_ffmpeg2theora (MediaFile mf, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += "ffmpeg2theora";
		s += " \"${inFile}\"";

		//TODO: Add support for multi-trim. Use ffmpeg for encoding theora?
		
		if (mf.StartPos > 0){
			s += " --starttime %.1f".printf(mf.StartPos);
		}

		if (mf.EndPos > 0){
			s += " --endtime %.1f".printf(mf.EndPos);
		}
		
		switch(video.get_string_member("mode")){
			case "vbr":
				s += " --videoquality " + video.get_string_member("quality");
				break;
			case "abr":
				s += " --videobitrate " + video.get_string_member("bitrate");
				break;
			case "2pass":
				s += " --two-pass --videobitrate " + video.get_string_member("bitrate");
				break;
		}

		//cropping
		if (mf.crop_enabled()) {
			s += " --croptop %d --cropbottom %d --cropleft %d --cropright %d".printf(mf.CropT,mf.CropB,mf.CropL,mf.CropR);
		}

		//resizing
		int w,h;
		bool rescale = calculate_video_resolution(mf, settings, out w, out h);
		if (rescale) {
			s += " --width %d --height %d".printf(w,h);
		}

		//fps
		int fpsNum = int.parse(video.get_string_member("fpsNum"));
		int fpsDenom = int.parse(video.get_string_member("fpsDenom"));
		if (fpsNum != 0 && fpsDenom != 0) {
			s += " --framerate %d/%d".printf(fpsNum,fpsDenom);
			mf.OutputFrameCount = (long) Math.floor((mf.Duration / 1000.0) * ((float)fpsNum/fpsDenom));
		}

		//audio
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			//mode
			switch (audio.get_string_member("mode")){
				case "vbr":
					s += " --audioquality " + audio.get_string_member("quality");
					break;
				case "abr":
					s += " --audiobitrate " + audio.get_string_member("bitrate");
					break;
			}

			//channels
			string channels = audio.get_string_member("channels");
			if (channels != "disable"){
				s += " --channels " + channels;
			}

			//sampling
			string sampling = audio.get_string_member("samplingRate");
			if (sampling != "disable"){
				s += " --samplerate " + sampling;
			}
		}
		else {
			s += " --noaudio";
		}

		//subs
		if (subs.get_string_member("mode") == "embed") {
			if (mf.SubExt == ".srt"){
				s += " --subtitles \"${subFile}\"";
			}
		}
		else {
			s += " --nosubtitles";
		}

		//other options
		if (video.get_string_member("options").strip() != "") {
			s += " " +  video.get_string_member("options").strip();
		}

		s += " --output \"${outputFile}\"";

		s += "\n";

		return s;
	}*/

	//playback ------------------------------

	public void play_video(MediaFile mf, VideoStream stream, Json.Object settings){
		if (file_exists(mf.Path)){
			
			string output = "";
			string error = "";

			string cmd = play_video_command(mf, stream, settings);
			cmd = "nohup %s".printf(cmd);

			try {
				Process.spawn_command_line_sync(cmd, out output, out error);
			}
			catch(Error e){
				log_error (e.message);
			}
		}
	}
	 
	private string play_video_command (MediaFile mf, VideoStream stream, Json.Object settings){
		string s = "";

		Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");

		s += PrimaryPlayer;

		//seek input
		if ((mf.StartPos > 0) && (mf.clip_list.size < 2)){
			s += " -ss %.1f".printf(mf.StartPos);
		}
		
		s += " -i \"%s\"".printf(mf.Path);

		//stop output
		if ((mf.EndPos > 0) && (mf.clip_list.size < 2)){
			s += " -to %.1f".printf(mf.EndPos - mf.StartPos);
		}
		
		//avconv_filters (resample, crop, resize, trim)
		s += avconv_filters(mf,settings,true,false);

		//disable audio and subs
		s += " -an -sn";

		s += "\n";
		
		return s;
	}

	public void play_audio(MediaFile mf, string sox_options){
		if (file_exists(mf.Path)){
			
			string output = "";
			string error = "";

			string cmd = play_audio_command(mf, sox_options);
			cmd = "%s".printf(cmd);

			log_debug(cmd);
			
			execute_command_script_sync(cmd, out output, out error);
		}
	}
	
	private string play_audio_command (MediaFile mf, string sox_options){
		string s = "";

		// decode audio -------------------------

		s += PrimaryEncoder;
		s += " -nostats";
		s += " -i \"%s\"".printf(mf.Path);
		s += " -f aiff";
		s += " -acodec pcm_s16le";
		s += " -vn -sn";
		s += " -y - | ";
		
		// process with SOX -----------------------
		
		s += "sox";
		s += " -t aiff -";
		s += " -t wav -";
		s += " -q";
		s += " %s".printf(sox_options.strip());
		s += " | ";

		// pass to ffplay -------------------------
		
		s += ff_player;
		s += " -i -";
		s += " -x 500 -y 100";
		s += "\n";
		
		return s;
	}

	public string ff_player{
		owned get{
			if (PrimaryEncoder == "ffmpeg"){
				return "ffplay";
			}
			else{
				return "avplay";
			}
		}
	}
	
	//video functions -----------------------
	
	private bool calculate_video_resolution (MediaFile mf, Json.Object settings, out int OutputWidth, out int OutputHeight){
		bool rescale = false;

		OutputWidth = mf.SourceWidth;
		OutputHeight = mf.SourceHeight;

		Json.Object video = (Json.Object) settings.get_object_member("video");

		if (mf.crop_enabled()){
			OutputWidth -= (mf.CropL + mf.CropR);
            OutputHeight -= (mf.CropT + mf.CropB);
            log_msg("Cropped: %.0fx%.0f".printf(OutputWidth,OutputHeight));
		}

		int maxw = int.parse(video.get_string_member("frameWidth"));
		int maxh = int.parse(video.get_string_member("frameHeight"));
		double iw = OutputWidth;
		double ow = iw;
		double ih = OutputHeight;
		double oh = ih;

		//flags for checking if resizing is actually required
		bool noResize = false;
		bool isUpscale = false;
		bool isSameSize = false;

		if (maxw == 0 && maxh == 0) {
			//do nothing
			noResize = true;
		}
		else if (maxw == 0){
			oh = maxh;
			ow = oh * (iw / ih);
			ow = Math.floor(ow);
			ow = ow - (ow % 4);
			log_msg("User height: %.0f".printf(maxh));
			log_msg("Set width: %.0f".printf(ow));
		}
		else if (maxh == 0){
			ow = maxw;
			oh = ow * (ih / iw);
			oh = Math.floor(oh);
			oh = oh - (oh % 4);
			log_msg("User width: %.0f".printf(maxw));
			log_msg("Set height: %.0f".printf(oh));
		}
		else{
			if (video.get_boolean_member("fitToBox") == false) {
				ow = maxw;
				oh = maxh;
			}
			else {
				log_msg("FitToBox is enabled");

				//fit height
				if (maxh > 0) {
					if (oh > maxh) { oh = maxh; }
					ow = oh * (iw / ih);
					ow = Math.floor(ow);
					ow = ow - (ow % 4);

					log_msg("Fit width: %.0f".printf(ow));
					rescale = true;
				}

				//fit width
				if (maxw > 0) {
					if (ow > maxw) { ow = maxw; }
					oh = ow * (ih / iw);
					oh = Math.floor(oh);
					oh = oh - (oh % 4);
					log_msg("Fit height: %.0f".printf(oh));
					rescale = true;
				}
			}
		}

		//check if video should be upscaled
        if (video.get_boolean_member("noUpscaling")) {
			if ((ow * oh) > (iw * ih)) {
				log_msg("NoUpscaling is enabled");
				log_msg("Will not resize since (%.0f * %.0f) > (%.0f * %.0f)".printf(ow,oh,iw,ih));
				isUpscale = true;
			}
		}

		//check if final size is same as original size
		if ((ow == OutputWidth)&&(oh == OutputHeight)) {
			isSameSize = true;
		}

		if (noResize || isUpscale || isSameSize) {
			//do not resize
			return false;
		}
		else {
			//resize
			OutputWidth = (int) ow;
			OutputHeight = (int) oh;
			log_msg("Resized: %.0fx%.0f".printf(ow,oh));
			return true;
		}
	}

	private string avconv_filters (MediaFile mf, Json.Object settings, bool keepVideo, bool keepAudio, bool resample = true, bool crop = true, bool scale = true){
		string s = "";
		string filters = "";

		Json.Object video = (Json.Object) settings.get_object_member("video");

		//trim
		string map = "";
		string vf_trim = "";
		avconv_vf_options_trim(mf, settings, keepVideo, keepAudio, out vf_trim, out map);
		//filters = vf_trim;
		
		if (keepVideo){
			//resample
			if (resample){
				int fpsNum = int.parse(video.get_string_member("fpsNum"));
				int fpsDenom = int.parse(video.get_string_member("fpsDenom"));
				if (fpsNum != 0 && fpsDenom != 0) {
					s += " -r %d/%d".printf(fpsNum,fpsDenom);
					mf.OutputFrameCount = (long)((mf.Duration / 1000.0) * ((float)fpsNum/fpsDenom));
				}
			}

			//crop
			if (crop){
				if (mf.crop_enabled()) {
					if (filters.length == 0){
						if (vf_trim.length == 0){
							filters += "[0:v]";
						}
						else {
							filters += ";[vout]";
						}
					}

					filters += "crop=%s".printf(mf.crop_values_libav());
				}
			}

			//scale
			if (scale){
				int w,h;
				bool rescale = calculate_video_resolution(mf, settings, out w, out h);
				if (rescale) {
					if (filters.length == 0){
						if (vf_trim.length == 0){
							filters += "[0:v]";
						}
						else {
							filters += ";[vout]";
						}
					}
					else{
						filters += ",";
					}
					
					filters += "scale=%d:%d".printf(w,h);
				}
			}

			if ((vf_trim.length > 0) && (filters.length > 0)){
				filters += "[vout]";
			}
		}

		filters = vf_trim + filters;
		
		if (filters.length > 0){
			s = " -filter_complex \"%s\"".printf(filters);

			if (map.length > 0){
				s += map;
			}
		}

		return s;
	}

	private void avconv_vf_options_trim (MediaFile mf, Json.Object settings, bool keepVideo, bool keepAudio, out string vf_trim, out string map){
		string s = "";
		vf_trim = "";
		map = "";
		
		if (mf.clip_list.size < 2){
			return;
		}

		string af = "";
		string audio_clips = "";
		string vf = "";
		string video_clips = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		string acodec = audio.get_string_member("codec");
		string vcodec = video.get_string_member("codec");
		//string format = general.get_string_member("format");
		
		if (keepVideo && mf.HasVideo && (vcodec != "disable")) {
			int index = 0;
			foreach(MediaClip clip in mf.clip_list){
				index++;
				vf += "[0:v]trim=start=%.3f:end=%.3f,setpts=PTS-STARTPTS[v%d];".printf(clip.StartPos, clip.EndPos, index);
				video_clips += "[v%d]".printf(index);
			}
		}

		if (keepAudio && mf.HasAudio && (acodec != "disable")) {
			int index = 0;
			foreach(MediaClip clip in mf.clip_list){
				index++;
				af += "[0:a]atrim=start=%.3f:end=%.3f,asetpts=PTS-STARTPTS[a%d];".printf(clip.StartPos, clip.EndPos, index);
				audio_clips += "[a%d]".printf(index);
			}
		}

		if ((vf.length > 0) && (af.length > 0)){
			s += vf;
			s += af;
			s += "%s%sconcat=n=%d:v=%d:a=%d[vout][aout]".printf(video_clips, audio_clips, mf.clip_list.size, 1, 1);
			map = " -map '[vout]' -map '[aout]' -strict -2";
		}
		else if (vf.length > 0){
			s += vf;
			s += "%s%sconcat=n=%d:v=%d:a=%d[vout]".printf(video_clips, "", mf.clip_list.size, 1, 0);
			map = " -map '[vout]' -strict -2";
		}
		else if (af.length > 0){
			s += af;
			s += "%s%sconcat=n=%d:v=%d:a=%d[aout]".printf("", audio_clips, mf.clip_list.size, 0, 1);
			map = " -map '[aout]' -strict -2";
		}

		vf_trim = s;
	}

	//encode audio ------------------------
	
	private string encode_audio_avconv (MediaFile mf, AudioStream stream, Json.Object settings){
		string s = "";

		Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");

		string format = general.get_string_member("format");
		bool sox_enabled = audio.get_boolean_member("soxEnabled");

		if (sox_enabled){
			s += decode_audio_avconv(mf, stream, settings, true);
			s += PrimaryEncoder;
			s += " -i -";
		}
		else{
			s += PrimaryEncoder;
			
			//seek input
			if ((mf.StartPos > 0) && (mf.clip_list.size < 2)){
				s += " -ss %.1f".printf(mf.StartPos);
			}
			
			s += " -i \"${inFile}\"";

			//map stream
			s += " -map 0:a:%d".printf(stream.TypeIndex);

			//stop output
			if ((mf.EndPos > 0) && (mf.clip_list.size < 2)){
				s += " -to %.1f".printf(mf.EndPos - mf.StartPos);
			}

			//avconv_filters (trim)
			s += avconv_filters(mf,settings, false, true);
		}

		switch (format){
		case "ac3":
			s += " -f ac3 -acodec ac3";
			s += " -b:a " + audio.get_string_member("bitrate") + "k";
			break;
		case "flac":
			s += " -f flac -acodec flac";
			break;
		case "wav":
			s += " -f wav";
			s += " -acodec " + audio.get_string_member("codec");
			break;
		default:
			string acodec = audio.get_string_member("codec");
			switch(acodec){
			case "aac": //if aac
			case "neroaac": //if aac
			case "libfdk_aac":
				s += " -f mp4 -acodec %s".printf(acodec);
				s += " -strict experimental"; //for compatibility with older versions; not required with newer versions where 'aac' is marked as stable.
				switch (audio.get_string_member("mode")){
				case "vbr":
					s += " -q:a " + audio.get_string_member("quality");
					break;
				case "abr":
					s += " -b:a " + audio.get_string_member("bitrate") + "k";
					break;
				}
				if (audio.has_member("aacProfile")){
					switch(audio.get_string_member("aacProfile")){
					case "auto":
						//do nothing
						break;
					case "lc":
						s += " -profile aac_low";
						break;
					case "he":
						s += " -profile aac_he";
						break;
					case "hev2":
						s += " -profile aac_he_v2";
						break;
					case "ld":
						s += " -profile aac_ld";
						break;
					case "eld":
						s += " -profile aac_eld";
						break;
					case "mpeg2_lc":
						s += " -profile mpeg2_aac_low";
						break;
					case "mpeg2_he":
						s += " -profile mpeg2_aac_he";
						break;
					case "mpeg2_hev2":
						//not supported
						break;
					}
				}
				break;
			}
			break;
		}

		//channels
		string channels = audio.get_string_member("channels");
		if (channels != "disable"){
			s += " -ac " + channels;
		}

		//sampling
		string sampling = audio.get_string_member("samplingRate");
		if (sampling != "disable"){
			s += " -ar " + sampling;
		}

		//tags
		bool copy_tags = true;
		if (settings.has_member("tags")){
			Json.Object tags = (Json.Object) settings.get_object_member("tags");
			copy_tags = tags.get_boolean_member("copyTags");
		}

		if (copy_tags){
			s += (mf.TrackName.length > 0) ? " -metadata 'title'=\"${tagTitle}\"" : "";
			s += (mf.TrackNumber.length > 0) ? " -metadata 'track'=\"${tagTrackNum}\"" : "";
			s += (mf.Artist.length > 0) ? " -metadata 'artist'=\"${tagArtist}\"" : "";
			s += (mf.Album.length > 0) ? " -metadata 'album'=\"${tagAlbum}\"" : "";
			s += (mf.Genre.length > 0) ? " -metadata 'genre'=\"${tagGenre}\"" : "";
			s += (mf.RecordedDate.length > 0) ? " -metadata 'year'=\"${tagYear}\"" : "";
			s += (mf.Comment.length > 0) ? " -metadata 'comment'=\"${tagComment}\"" : "";
		}
		else{
			s += " -map_metadata -1";
		}
		
		s += " -vn -sn";

		//output
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " -y \"${temp_audio_%d}\"".printf(stream.TypeIndex);
		}
		else {
			//encode to outputFile
			s += " -y \"${outputFile}\"";
		}

		s += "\n";
		
		return s;
	}

	private string encode_audio_mp3lame (MediaFile mf, AudioStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");

		s += decode_audio_avconv(mf, stream, settings, false);
		s += "lame --nohist --brief -q 5 --replaygain-fast";
		switch (audio.get_string_member("mode")){
			case "vbr":
				s += " -V " + audio.get_string_member("quality");
				break;
			case "abr":
				s += " --abr " + audio.get_string_member("bitrate");
				break;
			case "cbr":
				s += " -b " + audio.get_string_member("bitrate");
				break;
			case "cbr-strict":
				s += " -b " + audio.get_string_member("bitrate") + " --cbr";
				break;
		}

		//tags
		bool copy_tags = true;
		if (settings.has_member("tags")){
			Json.Object tags = (Json.Object) settings.get_object_member("tags");
			copy_tags = tags.get_boolean_member("copyTags");
		}

		if (copy_tags){
			s += (mf.TrackName.length > 0) ? " --tt \"${tagTitle}\"" : "";
			s += (mf.TrackNumber.length > 0) ? " --tn \"${tagTrackNum}\"" : "";
			s += (mf.Artist.length > 0) ? " --ta \"${tagArtist}\"" : "";
			s += (mf.Album.length > 0) ? " --tl \"${tagAlbum}\"" : "";
			s += (mf.Genre.length > 0) ? " --tg \"${tagGenre}\"" : "";
			s += (mf.RecordedDate.length > 0) ? " --ty \"${tagYear}\"" : "";
			s += (mf.Comment.length > 0) ? " --tc \"${tagComment}\"" : "";
		}

		s += " -";
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " \"${temp_audio_%d}\"".printf(stream.TypeIndex);
		}
		else {
			//encode to outputFile
			s += " \"${outputFile}\"";
		}
		s += "\n";

		return s;
	}

	private string encode_audio_neroaac (MediaFile mf, AudioStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");

		s += decode_audio_avconv(mf, stream, settings, false);
		
		s += "neroAacEnc -ignorelength";
		
		switch (audio.get_string_member("mode")){
			case "vbr":
				s += " -q " + audio.get_string_member("quality");
				break;
			case "abr":
				s += " -br " + audio.get_string_member("bitrate");
				break;
			case "cbr":
				s += " -cbr " + audio.get_string_member("bitrate");
				break;
		}

		if (audio.has_member("aacProfile")){
			switch(audio.get_string_member("aacProfile")){
			case "auto":
				//do nothing
				break;
			case "lc":
				s += " -lc";
				break;
			case "he":
				s += " -he";
				break;
			case "hev2":
				s += " -hev2";
				break;
			}
		}
		
		s += " -if -";
		
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " -of \"${temp_audio_%d}\"".printf(stream.TypeIndex);
			s += "\n";
		}
		else {
			//encode to outputFile
			s += " -of \"${outputFile}\"";
			s += "\n";
			
			//add tags
			string alltags = "";
			string path = get_cmd_path ("neroAacTag");
			if ((path != null) && (path.length > 0)){

				//tags
				bool copy_tags = true;
				if (settings.has_member("tags")){
					Json.Object tags = (Json.Object) settings.get_object_member("tags");
					copy_tags = tags.get_boolean_member("copyTags");
				}

				if (copy_tags){
					alltags += (mf.TrackName.length > 0) ? " -meta:title=\"${tagTitle}\"" : "";
					alltags += (mf.TrackNumber.length > 0) ? " -meta:track=\"${tagTrackNum}\"" : "";
					alltags += (mf.Artist.length > 0) ? " -meta:artist=\"${tagArtist}\"" : "";
					alltags += (mf.Album.length > 0) ? " -meta:album=\"${tagAlbum}\"" : "";
					alltags += (mf.Genre.length > 0) ? " -meta:genre=\"${tagGenre}\"" : "";
					alltags += (mf.RecordedDate.length > 0) ? " -meta:year=\"${tagYear}\"" : "";
					alltags += (mf.Comment.length > 0) ? " -meta:comment=\"${tagComment}\"" : "";
					
					if (alltags.length > 0){
						s += "neroAacTag";
						s += " \"${outputFile}\"";
						s += alltags;
						s += "\n";
					}
				}
			}			
		}

		return s;
	}

	private string encode_audio_fdkaac (MediaFile mf, AudioStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");

		//decode to WAV file with avconv
		s += decode_audio_avconv(mf, stream, settings, false, "audio.wav");

		//encode with aac-enc
		s += "aac-enc";
		switch (audio.get_string_member("mode")){
			case "vbr":
				s += " -v " + audio.get_string_member("quality");
				break;
			case "abr":
				s += " -r " + audio.get_string_member("bitrate");
				break;
		}
		if (audio.has_member("aacProfile")){
			switch(audio.get_string_member("aacProfile")){
			case "auto":
				//do nothing
				break;
			case "lc":
				s += " -t 2";
				break;
			case "he":
				s += " -t 5";
				break;
			case "hev2":
				s += " -t 29";
				break;
			case "ld":
				s += " -t 23";
				break;
			case "eld":
				s += " -t 39";
				break;
			case "mpeg2_lc":
				s += " -t 129";
				break;
			case "mpeg2_he":
				s += " -t 132";
				break;
			case "mpeg2_hev2":
				s += " -t 156";
				break;
			}
		}
		s += " audio.wav audio.aac";
		s += "\n";

		
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += mux_avconv_aac_to_mp4(mf, settings, "audio.aac","${temp_audio_%d}".printf(stream.TypeIndex));
		}
		else {
			//encode to outputFile
			s += mux_avconv_aac_to_mp4(mf, settings, "audio.aac","${outputFile}");
		}

		s += "\n";

		return s;
	}

	private string encode_audio_opus (MediaFile mf, AudioStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");

		s += decode_audio_avconv(mf, stream, settings, true);
		s += "opusenc";

		//tags
		bool copy_tags = true;
		if (settings.has_member("tags")){
			Json.Object tags = (Json.Object) settings.get_object_member("tags");
			copy_tags = tags.get_boolean_member("copyTags");
		}

		if (copy_tags){
			s += (mf.TrackName.length > 0) ? " --title \"${tagTitle}\"" : "";
			s += (mf.TrackNumber.length > 0) ? " --comment=\"track=${tagTrackNum}\"" : "";
			s += (mf.Artist.length > 0) ? " --artist \"${tagArtist}\"" : "";
			s += (mf.Album.length > 0) ? " --comment=\"album=${tagAlbum}\"" : "";
			s += (mf.Genre.length > 0) ? " --comment=\"genre=${tagGenre}\"" : "";
			s += (mf.RecordedDate.length > 0) ? " --comment=\"year=${tagYear}\"" : "";
			s += (mf.Comment.length > 0) ? " --comment=\"comment=${tagComment}\"" : "";
		}

		//options
		s += " --bitrate " + audio.get_string_member("bitrate");
		switch (audio.get_string_member("mode")){
			case "vbr":
				s += " --vbr";
				break;
			case "abr":
				s += " --cvbr";
				break;
			case "cbr":
				s += " --hard-cbr";
				break;
		}

		switch (audio.get_string_member("opusOptimize")){
			case "none":
				//do nothing
				break;
			case "speech":
				s += " --speech";
				break;
			case "music":
				s += " --music";
				break;
		}

		//input
		s += " -";

		//output
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " \"${temp_audio_%d}\"".printf(stream.TypeIndex);
		}
		else {
			//encode to outputFile
			s += " \"${outputFile}\"";
		}
		s += "\n";

		return s;
	}

	private string encode_audio_oggenc (MediaFile mf, AudioStream stream, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += decode_audio_avconv(mf, stream, settings, false);
		s += "oggenc --quiet";

		//mode
		switch (audio.get_string_member("mode")){
			case "vbr":
				s += " --quality " + audio.get_string_member("quality");
				break;
			case "abr":
				s += " --bitrate " + audio.get_string_member("bitrate");
				break;
		}

		//tags
		bool copy_tags = true;
		if (settings.has_member("tags")){
			Json.Object tags = (Json.Object) settings.get_object_member("tags");
			copy_tags = tags.get_boolean_member("copyTags");
		}

		if (copy_tags){
			s += (mf.TrackName.length > 0) ? " --title \"${tagTitle}\"" : "";
			s += (mf.TrackNumber.length > 0) ? " --comment=\"track=${tagTrackNum}\"" : "";
			s += (mf.Artist.length > 0) ? " --artist \"${tagArtist}\"" : "";
			s += (mf.Album.length > 0) ? " --album \"${tagAlbum}\"" : "";
			s += (mf.Genre.length > 0) ? " --genre \"${tagGenre}\"" : "";
			s += (mf.RecordedDate.length > 0) ? " --date \"${tagYear}\"" : "";
			s += (mf.Comment.length > 0) ? " --comment='comment=${tagComment}'" : "";
		}

		//output
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " --output \"${temp_audio_%d}\"".printf(stream.TypeIndex);
		}
		else {

			//encode to output file -- add subs
			
			foreach(TextStream stm in mf.text_list){
				if (!stm.IsSelected){
					continue;
				}
				
				//encode subs
				if (mf.HasSubs && (subs.get_string_member("mode") == "embed")) {
					s += " --lyrics \"${temp_subs_%d}\"".printf(stm.TypeIndex);
				}
			}
		
			//encode to outputFile
			s += " --output \"${outputFile}\"";
		}

		//input
		s += " -";

		s += "\n";

		return s;
	}

	//audio functions -----------------------

	private string process_audio_sox(MediaFile mf, Json.Object settings, string temp_file_name = ""){
		string s = "";

		Json.Object audio = (Json.Object) settings.get_object_member("audio");

		s += "sox";
		s += " -t aiff -";

		if (temp_file_name.length > 0){
			s += " -t wav '%s'".printf(temp_file_name);
		}
		else{
			s += " -t wav -";
		}
		
		s += " -q"; //silent

		string sox_bass = audio.get_string_member("soxBass");
		string sox_treble = audio.get_string_member("soxTreble");
		string sox_pitch = audio.get_string_member("soxPitch");
		string sox_tempo = audio.get_string_member("soxTempo");
		string sox_fade_in = audio.get_string_member("soxFadeIn");
		string sox_fade_out = audio.get_string_member("soxFadeOut");
		string sox_fade_type = audio.get_string_member("soxFadeType");
		bool sox_normalize = audio.get_boolean_member("soxNormalize");
		bool sox_earwax = audio.get_boolean_member("soxEarwax");

		if (sox_bass != "0"){
			s += " bass " + sox_bass;
		}
		if (sox_treble != "0"){
			s += " treble " + sox_treble;
		}
		if (sox_pitch != "1.0"){
			s += " pitch " + sox_pitch;
		}
		if (sox_tempo != "1.0"){
			s += " tempo " + sox_tempo;
		}
		if ((sox_fade_in != "0") || (sox_fade_out != "0")){
			s += " fade " + sox_fade_type + " " + sox_fade_in;
			if (sox_fade_out != "0"){
				s += " %ld".printf(mf.Duration) + " " + sox_fade_out;
			}
		}
		if (sox_normalize){
			s += " norm";
		}
		if (sox_earwax){
			s += " earwax";
		}

		if (temp_file_name.length > 0){
			s += "\n";
		}
		else{
			s += " | ";
		}

		return s;
	}

	//muxing -------------------------------------
	
	private string mux_mkvmerge (MediaFile mf, Json.Object settings){
		string s = "";

		Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		string format = general.get_string_member("format");

		s += "mkvmerge";

		//webm compliance
		if (format == "webm") {
			s += " --webm";
		}

		//output
		s += " --output \"${outputFile}\"";

		//add video tracks
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			foreach(VideoStream stream in mf.video_list){
				if (stream.IsSelected){
					s += " --compression -1:none \"${temp_video_%d}\"".printf(stream.TypeIndex);
				}
			}
		}

		//add audio tracks
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			foreach(AudioStream stream in mf.audio_list){
				if (stream.IsSelected){
					s += " --compression -1:none";
					if (stream.LangCode.length > 0){
						s += " --language -1:%s".printf(stream.LangCode);
						if (stream.LangCode == DefaultLanguage){
							s += " --default-track -1:yes";
						}
					}
					s += " \"${temp_audio_%d}\"".printf(stream.TypeIndex);
				}
			}
		}

		//TODO: Add option to specify default subtitle track

		//add subtitle tracks
		if (format != "webm") {
			if (mf.HasSubs && (subs.get_string_member("mode") == "embed")) {
				foreach(TextStream stm in mf.text_list){
					if (stm.IsSelected){
						if (!stm.IsExternal){
							s += " --compression -1:none";
							if (stm.LangCode.length > 0){
								s += " --language -1:%s".printf(stm.LangCode);
								if (stm.LangCode == DefaultLanguage){
									s += " --default-track -1:yes";
								}
							}
							s += " \"${temp_subs_%d}\"".printf(stm.TypeIndex);
						}
						else if (stm.IsExternal && (stm.SubExt == ".srt" || stm.SubExt == ".sub" || stm.SubExt == ".ssa") || (stm.SubExt == ".ass")){
							s += " --compression -1:none";
							if (stm.LangCode.length > 0){
								s += " --language -1:%s".printf(stm.LangCode);
								if (stm.LangCode == DefaultLanguage){
									s += " --default-track -1:yes";
								}
							}
							s += " \"${temp_subs_%d}\"".printf(stm.TypeIndex);
						}
					}
				}
			}
		}
		else{
			//WebM currently does not support subtitles
		}

		s += "\n";

		return s;
	}

	private string mux_mp4box (MediaFile mf, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += "MP4Box -new";

		//add video tracks
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			foreach(VideoStream stream in mf.video_list){
				if (stream.IsSelected){
					s += " -add \"${temp_video_%d}\"".printf(stream.TypeIndex);
				}
			}
		}

		//add audio tracks
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			foreach(AudioStream stream in mf.audio_list){
				if (stream.IsSelected){
					s += " -add \"${temp_audio_%d}\"".printf(stream.TypeIndex);
				}
			}
		}

		//add subtitle tracks
		if (mf.HasSubs && (subs.get_string_member("mode") == "embed")) {
			foreach(TextStream stm in mf.text_list){
				if (stm.IsSelected){
					if (!stm.IsExternal){
						s += " -add \"${temp_subs_%d}\"".printf(stm.TypeIndex);
					}
					else if (stm.IsExternal && (stm.SubExt == ".srt" || stm.SubExt == ".sub" || stm.SubExt == ".ttxt" || stm.SubExt == ".xml")){
						s += " -add \"${temp_subs_%d}\"".printf(stm.TypeIndex);
					}
				}
			}
		}

		s += " \"${outputFile}\"";
		s += "\n";

		return s;
	}

	private string mux_mp4box_aac_to_mp4(string input_file, string output_file){

		// deprecated; does not support tags
		
		string s = "";

		s += "MP4Box -new";
		s += " -add \"%s\"".printf(input_file);
		s += " \"%s\"".printf(output_file);
		s += "\n";

		return s;
	}

	private string mux_avconv_aac_to_mp4 (MediaFile mf, Json.Object settings, string input_file, string output_file){
		
		string s = "";

		//tags
		bool copy_tags = true;
		if (settings.has_member("tags")){
			Json.Object tags = (Json.Object) settings.get_object_member("tags");
			copy_tags = tags.get_boolean_member("copyTags");
		}
		
		s += PrimaryEncoder;
		s += " -i \"%s\"".printf(input_file);
		s += " -f mp4";
		s += " -c:a copy -vn -sn"; // 
		s += " -bsf:a aac_adtstoasc";
		
		if (copy_tags){
			s += (mf.TrackName.length > 0) ? " -metadata 'title'=\"${tagTitle}\"" : "";
			s += (mf.TrackNumber.length > 0) ? " -metadata 'track'=\"${tagTrackNum}\"" : "";
			s += (mf.Artist.length > 0) ? " -metadata 'artist'=\"${tagArtist}\"" : "";
			s += (mf.Album.length > 0) ? " -metadata 'album'=\"${tagAlbum}\"" : "";
			s += (mf.Genre.length > 0) ? " -metadata 'genre'=\"${tagGenre}\"" : "";
			s += (mf.RecordedDate.length > 0) ? " -metadata 'year'=\"${tagYear}\"" : "";
			s += (mf.Comment.length > 0) ? " -metadata 'comment'=\"${tagComment}\"" : "";
		}
		else{
			s += " -map_metadata -1";
		}
		
		s += " -y \"%s\"".printf(output_file);
		s += "\n";
		
		return s;
	}

	private string mux_avconv (MediaFile mf, Json.Object settings){
		string s = "";
		string map = "";
		string metadata = "";
		int inputIndex = -1;
		int outTypeIndex = -1;
		
		Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");
		string format = general.get_string_member("format");

		s += PrimaryEncoder;

		//add video tracks
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			foreach(VideoStream stream in mf.video_list){
				if (stream.IsSelected){
					s += " -i \"${temp_video_%d}\"".printf(stream.TypeIndex);
					map += " -map %d:0".printf(++inputIndex);
				}
			}
		}

		//add audio tracks ---------------

		outTypeIndex = -1;
		
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			foreach(AudioStream stream in mf.audio_list){
				if (stream.IsSelected){
					outTypeIndex++;
					
					s += " -i \"${temp_audio_%d}\"".printf(stream.TypeIndex);
					map += " -map %d:0".printf(++inputIndex);

					if ((stream.LangCode.length > 0) && (LanguageCodes.map_2_to_3.has_key(stream.LangCode))){
						metadata += " -metadata:s:a:%d language=%s".printf(outTypeIndex, LanguageCodes.map_2_to_3[stream.LangCode]);
					}
				}
			}
		}

		//add subtitle tracks ------------------
		
		outTypeIndex = -1;
		
		if (mf.HasSubs && (subs.get_string_member("mode") == "embed")) {
			foreach(TextStream stm in mf.text_list){
				if (stm.IsSelected){
					outTypeIndex++;
					
					if (!stm.IsExternal){
						s += " -i \"${temp_subs_%d}\"".printf(stm.TypeIndex);
						map += " -map %d:0".printf(++inputIndex);
						
						if ((stm.LangCode.length > 0) && (LanguageCodes.map_2_to_3.has_key(stm.LangCode))){
							metadata += " -metadata:s:s:%d language=%s".printf(outTypeIndex, LanguageCodes.map_2_to_3[stm.LangCode]);
						}
					}
					else if (stm.IsExternal && (stm.SubExt == ".srt" || stm.SubExt == ".sub" || stm.SubExt == ".ttxt" || stm.SubExt == ".xml")){
						s += " -i \"${temp_subs_%d}\"".printf(stm.TypeIndex);
						map += " -map %d:0".printf(++inputIndex);

						if ((stm.LangCode.length > 0) && (LanguageCodes.map_2_to_3.has_key(stm.LangCode))){
							metadata += " -metadata:s:s:%d language=%s".printf(outTypeIndex, LanguageCodes.map_2_to_3[stm.LangCode]);
						}
					}
				}
			}
		}

		//set output mappings

		s += map;

		//set language metadata
		
		s += metadata;

		switch(format){
			case "mp4v":
				s += " -f mp4";
				break;
			case "mkv":
				s += " -f matroska";
				break;
		}
		
		s += " -c:a copy -c:v copy";

		if (subs.get_string_member("mode") == "embed") {
			switch(format){
			case "mp4v":
				s += " -c:s mov_text";
				break;
			case "mkv":
				s += " -c:s ass";
				break;
			}
		}
		else{
			s += " -sn";
		}

		s += " -y \"${outputFile}\"";
		s += "\n";

		return s;
	}

	private string mux_oggz(MediaFile mf, Json.Object settings){
		string s = "";

		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += "oggz merge";

		s += " -o \"${outputFile}\"";

		//add video tracks
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			foreach(VideoStream stream in mf.video_list){
				if (stream.IsSelected){
					s += " \"${temp_video_%d}\"".printf(stream.TypeIndex);
				}
			}
		}

		//add audio tracks
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			foreach(AudioStream stream in mf.audio_list){
				if (stream.IsSelected){
					s += " \"${temp_audio_%d}\"".printf(stream.TypeIndex);
				}
			}
		}

		//add subtitle tracks
		if (mf.HasSubs && subs.get_string_member("mode") == "embed") {
			foreach(TextStream stream in mf.text_list){
				if (stream.IsSelected){
					s += " \"subs_kate_%d.ogg\"".printf(stream.TypeIndex);
				}
			}
		}
		
		s += "\n";
		
		return s;
	}
}

public class Encoder : GLib.Object{
	public string Command = "";
	public string Name = "";
	public string Description = "";
	public bool IsAvailable = false;

	public Encoder(string cmd, string name, string desc){
		Command = cmd;
		Name = name;
		Description = desc;
	}

	public bool CheckAvailability(){
		bool available = false;
		string str = get_cmd_path (Command);
		if ((str != null)&&(str.length > 0)){
			available = true;
		}
		IsAvailable = available;
		return IsAvailable;
	}
}

public class FFmpegCodec : GLib.Object{
	public string Name = "";
	public string Description = "";
	public bool DecodingSupported = false;
	public bool EncodingSupported = false;
	public string CodecType = "";

	public FFmpegCodec(){
	}

	public static Gee.HashMap<string,FFmpegCodec> check_codec_support(string av_encoder){
		var list = new Gee.HashMap<string,FFmpegCodec>();

		string output = execute_command_sync_get_output("%s -codecs".printf(av_encoder));

		Regex regex = null;
		MatchInfo match;
		
		try{
			//D.V.L. mpegvideo_xvmc       MPEG-1/2 video XvMC (X-Video Motion Compensation)
			//DEA.L. opus                 Opus (Opus Interactive Audio Codec) (decoders: opus libopus ) (encoders: libopus )
			regex = new Regex("""^([D\.])([E\.])([VAS])([I\.])([L\.])([S\.])[ \t]+([^ \t]*)[ \t]+([^ \t]*)$""");
		}
		catch (Error e) {
			log_error (e.message);
		}

		foreach(string line in output.split("\n")){
			if (regex.match (line, 0, out match)){
				FFmpegCodec codec = new FFmpegCodec();
				codec.DecodingSupported = (match.fetch(1).strip() == "D");
				codec.EncodingSupported = (match.fetch(2).strip() == "E");
				codec.CodecType = match.fetch(3).strip();
				codec.Name = match.fetch(7).strip();
				codec.Description = match.fetch(8).strip();
				list[codec.Name] = codec;
			}
		}

		if (!list.has_key("libfdk_aac")){
			FFmpegCodec codec = new FFmpegCodec();
			codec.CodecType = "A";
			codec.Name = "libfdk_aac";
			codec.Description = "Fraunhofer FDK AAC Encoder";
			list[codec.Name] = codec;
		}
		
		return list;
	}
}

