/*
 * Main.vala
 * 
 * Copyright 2012 Tony George <teejee2008@gmail.com>
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
using Soup;

public Main App;
public const string AppName = "Selene Media Encoder";
public const string AppVersion = "1.6";
public const bool LogTimestamp = true;
public bool UseConsoleColors = false;

/*
const string GETTEXT_PACKAGE = Config.GETTEXT_PACKAGE;
const string LOCALE_DIR = "/usr/local/lib/locale";
const string VERSION = "1.0";
*/

public enum FileStatus
{
	PENDING,
	RUNNING,
	PAUSED,
	DONE,
	SKIPPED,
	SUCCESS,
	ERROR
}

public enum AppStatus
{
	NOTSTARTED, //initial state
	RUNNING,	
	PAUSED,	   
	IDLE,		//batch completed
	WAITFILE    //waiting for files
}

public class MediaFile : GLib.Object
{
	public string Path;
	public string Name;
	public string Title;
	public string Extension;
	public string Location;
	
	public int64 Size = 0;
	public long Duration = 0;
	
	public string SubFile;
	public string SubName;
	public string SubExt;
	
	public int CropW = 0;
	public int CropH = 0;
	public int CropL = 0;
	public int CropR = 0;
	public int CropT = 0;
	public int CropB = 0;
	public bool AutoCropError = false;
	
	public FileStatus Status = FileStatus.PENDING;
	public bool IsValid;
	public string ProgressText = "Queued";
	public int ProgressPercent = 0;
	
	public string InfoText;
	public bool HasAudio = false;
	public bool HasVideo = false;
	public int SourceWidth = 0;
	public int SourceHeight = 0;
	public double SourceFrameRate = 0;
	public int AudioChannels = 0;
	
	public string ScriptFile;
	public string TempDirectory;
	public string LogFile;
	public string OutputFilePath;
	public long OutputFrameCount = 0;
	
	public MediaFile(string filePath)
	{
		this.IsValid = false;
		if (Utility.file_exists (filePath) == false) { return; }
		
		// set file properties ------------
		
		File f = File.new_for_path (filePath);
		File fp = f.get_parent ();
		
		this.Path = filePath;
		this.Name = f.get_basename ();
		this.Title = Name[0: Name.last_index_of(".",0)];
		this.Extension = Name[Name.last_index_of(".",0):Name.length];
		this.Location = fp.get_path ();
		//stderr.printf(@"file=$filePath, name=$Name, title=$Title, ext=$Extension, dir=$Location\n");
		
		FileInfo fi = null;
		
		try{
			fi = f.query_info ("*", FileQueryInfoFlags.NONE, null);
			this.Size = fi.get_size ();
		}
		catch (Error e) {
			log_error (e.message);
		}

		// get media information ----------
		
		query_mediainfo ();
		if (Duration == 0) { return; }
		
		// search for subtitle files ---------------
		
		try{
	        var enumerator = fp.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			var fileInfo = enumerator.next_file ();
	        while (fileInfo != null) {
	            if (fileInfo.get_file_type() == FileType.REGULAR) {
		            string fname = fileInfo.get_name().down();
		            if (fname.has_prefix(Title.down()) && (fname.has_suffix (".srt")||fname.has_suffix (".sub")||fname.has_suffix (".ssa")||fname.has_suffix (".ttxt")||fname.has_suffix (".xml")||fname.has_suffix (".lrc")))
		            {
			            SubName = fileInfo.get_name ();
			            SubFile = Location + "/" + SubName;
	                	SubExt = SubFile[SubFile.last_index_of(".",0):SubFile.length].down();
	                	//log ("file=%s, name=%s, ext=%s\n".printf(SubFile, SubName, SubExt));
	                }
	            }
	            fileInfo = enumerator.next_file ();
	        }
        }
        catch(Error e){
	        log_error (e.message);
	    }
	    
		this.IsValid = true;
	}
	
	public void query_mediainfo ()
	{
		this.InfoText = Utility.get_mediainfo (Path);
		
		if (InfoText == null || InfoText == ""){
			return;
		}
		
		string sectionType = "";
		
		foreach (string line in InfoText.split ("\n")){
			if (line == null || line.length == 0) { continue; }
			
			if (line.contains (":") == false)
			{
				if (line.contains ("Audio")){
					sectionType = "audio";
					HasAudio = true;
				}
				else if (line.contains ("Video")){
					sectionType = "video";
					HasVideo = true;
				}
				else if (line.contains ("General")){
					sectionType = "general";
				}
			}
			else{
				string[] arr = line.split (": ");
				if (arr.length != 2) { continue; }
				
				string key = arr[0].strip ();
				string val = arr[1].strip ();
				
				if (sectionType	== "general"){
					switch (key.down ()) {
						case "duration":
							Duration = 0;
							foreach(string p in val.split(" ")){
								string part = p.strip().down();
								if (part.contains ("h") || part.contains ("hr"))
									Duration += long.parse(part.replace ("hr","").replace ("h","")) * 60 * 60 * 1000;
								else if (part.contains ("mn") || part.contains ("min"))
									Duration += long.parse(part.replace ("min","").replace ("mn","")) * 60 * 1000;
								else if (part.contains ("ms"))
									Duration += long.parse(part.replace ("ms",""));
								else if (part.contains ("s"))
									Duration += long.parse(part.replace ("s","")) * 1000;
							}
							break;
					}
				}
				else if (sectionType == "video"){
					switch (key.down ()) {
						case "width":
							SourceWidth = int.parse(val.replace ("pixels","").replace (" ","").strip ());
							break;
						case "height":
							SourceHeight = int.parse(val.replace ("pixels","").replace (" ","").strip ());
							break;
						case "frame rate":
							SourceFrameRate = int.parse(val.replace ("fps","").replace (" ","").strip ());
							break;
					}
				}
				else if (sectionType == "audio"){
					switch (key.down ()) {
						case "channel(s)":
							AudioChannels = int.parse(val.replace ("channels","").replace ("channel","").strip ());
							break;
					}
				}
			}
		}
	}
	
	public void prepare (string baseTempDir)
	{
		this.TempDirectory = baseTempDir + "/" + Utility.timestamp2() + " - " + this.Name;
		this.LogFile = this.TempDirectory + "/" + "log.txt";
		this.ScriptFile = this.TempDirectory + "/convert.sh";
		this.OutputFilePath = "";
		Utility.create_dir (this.TempDirectory);
		
		//initialize output frame count
		if (HasVideo && Duration > 0 && SourceFrameRate > 1) {
			OutputFrameCount = (long) ((Duration / 1000.0) * (SourceFrameRate));
		}
		else{
			OutputFrameCount = 0;
		}
	}
	
	public bool crop_detect ()
	{
		if (HasVideo == false) { 
			AutoCropError = true;
			return false; 
		}
		
		string params = Utility.get_file_crop_params (Path);
		string[] arr = params.split (":");

		if (arr.length == 4){
			CropW = int.parse (arr[0]);
			CropH = int.parse (arr[1]);
			CropL = int.parse (arr[2]);
			CropT = int.parse (arr[3]);
		}
		
		CropR = SourceWidth - CropW - CropL;
		CropB = SourceHeight - CropH - CropT;
		
		if ((CropW == 0) && (CropH == 0)){
			AutoCropError = true;
			return false;
		}
		else
			return true;
	}
	
	public bool crop_enabled ()
	{
		if ((CropW == 0)&&(CropH == 0)&&(CropL == 0)&&(CropT == 0))
			return false;
		else
			return true;
	}
	
	public void crop_reset ()
	{
		CropW = 0;
		CropH = 0;
		CropL = 0;
		CropT = 0;
		CropR = 0;
		CropB = 0;
	}

	public string crop_values_info ()
	{
		if (crop_enabled())
			return "%i:%i:%i:%i".printf(CropL,CropT,CropR,CropB);
		else if (AutoCropError)
			return "N/A";
		else
			return "";
	}
	
	public string crop_values_libav ()
	{
		if (crop_enabled())
			return "%i:%i:%i:%i".printf(CropW,CropH,CropL,CropT);
		else
			return "iw:ih:0:0";
	}	
	
	public string crop_values_x264 ()
	{
		if (crop_enabled())
			return "%i,%i,%i,%i".printf(CropL,CropT,CropR,CropB);
		else
			return "0,0,0,0";
	}
	
	public void preview_output ()
	{
		string output = "";
		string error = "";
		
		try {
			Process.spawn_command_line_sync("avplay -i " + Utility.double_quote (Path) + " -vf crop=" + crop_values_libav (), out output, out error);
		}
		catch(Error e){
	        log_error (e.message);
	    }
	}
}

public class ScriptFile : GLib.Object
{
	public string Path;
	public string Name;
	public string Title;
	public string Extension;
	public string Folder;
	
	public ScriptFile(string filePath)
	{
		Path = filePath;
	    Name = GLib.Path.get_basename (filePath);
	    Folder = GLib.Path.get_dirname (filePath);
	    
	    int index = Name.index_of(".");
	    if (index != -1){
			Title = Name[0:Name.last_index_of(".")];
			Extension = Name[Name.last_index_of("."):Name.length];
		}
		else{
			Title = Name;
			Extension = "";
		}
	}
}

public class Main : GLib.Object
{
	public Gee.ArrayList<MediaFile> InputFiles;

	public string ScriptsFolder_Official = "";
	public string ScriptsFolder_Custom = "";
	public string PresetsFolder_Official = "";
	public string PresetsFolder_Custom = "";
	public string SharedImagesFolder = "";
	
	public string TempDirectory;
	public string OutputDirectory = "";
	public string BackupDirectory = "";
	private string ConfigDirectory;

	public ScriptFile SelectedScript;
	public MediaFile CurrentFile;
	public string CurrentLine;
	public string StatusLine;
	public double Progress;
	
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
	
	private string blankLine = "";
	
	public static int main (string[] args) 
	{
		// set locale
		/*Intl.setlocale(GLib.LocaleCategory.ALL, "");
		Intl.bindtextdomain("selene", "/usr/local/share/locale");
		Intl.bind_textdomain_codeset("selene", "UTF-8");
		Intl.textdomain("selene");*/
		
		// show help
		
		if (args.length > 1) {
			switch (args[1].down()) {
				case "--help":
				case "-h":
					stdout.printf (Main.help_message ());
					return 0;
			}
		}

		// init app

		Gtk.init (ref args);
		
		
		/*
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
		Environment.set_application_name(GETTEXT_PACKAGE);
		*/
		
		App = new Main(args[0]);
	    
	    // check if terminal supports colors
		
		string term = Environment.get_variable ("TERM").down ();
		UseConsoleColors = (term == "xterm");
		
		// check dependencies
		
		string str = Utility.get_cmd_path ("mediainfo");
		if ((str == null)||(str == "")){
			Utility.messagebox_show("Missing Dependency", "Following packages were not found:\n\nmediainfo\n\nNot possible to continue!", true);
			return 1;
		}
		
		// get command line arguments
		
		for (int k = 1; k < args.length; k++) // Oth arg is app path 
		{
			switch (args[k].down ()){
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
						else if (Utility.dir_exists (args[k])){
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
						else if (Utility.dir_exists (args[k])){
							App.BackupDirectory = args[k];
						}
					}
					break;
					
				case "--console":
					App.ConsoleMode = true;
					break;
					
				case "--debug":
					App.DebugMode = true;
					break;
				
				case "--shutdown":
					if (App.AdminMode) {
						App.Shutdown = true;
						log_msg ("System will be shutdown after completion");
					}
					else {
						log_error ("Warning: User does not have Admin priviledges. '--shutdown' will be ignored.");
					}
					break;
				
				case "--background":
					App.BackgroundMode = true;
					App.set_priority ();
					break;

				default:
					App.add_file (Utility.resolve_relative_path(args[k]));
					break;
			}
		}
		
		// check UI mode
		
		if ((App.SelectedScript == null)||(App.InputFiles.size == 0))
			App.ConsoleMode = false;
		
		// show window
		
		if (App.ConsoleMode){
			if (App.InputFiles.size == 0){
				log_error ("Input queue is empty! Please specify files to convert.");
				return 1;
			}
			App.start_input_thread ();
			App.convert_begin ();
		}
		else{
			var window = new MainWindow ();
			window.destroy.connect (App.exit_app);
			window.show_all ();
		}

	    Gtk.main ();
	    
	    return 0;
	}
	
	public static string help_message ()
	{
		string msg = "\n" + AppName + " v" + AppVersion + " by Tony George (teejee2008@gmail.com)\n";
		msg += Environment.get_prgname () + " [options] <input-file-list>";
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
	
	public Main(string arg0)
	{
		InputFiles = new Gee.ArrayList<MediaFile>();

		// check for admin priviledges
		
		AdminMode = Utility.user_is_admin ();
		
		// check for notify-send
		
		string path = Utility.get_cmd_path ("notify-send");
		if ((path != null)&&(path != "")){
			ShowNotificationPopups = true;
		}

		// set default directory paths
		
		string homeDir = Environment.get_home_dir ();
		this.TempDirectory = Environment.get_tmp_dir () + "/" + Environment.get_prgname ();	
		Utility.create_dir (this.TempDirectory);	
		this.OutputDirectory = "";
		this.BackupDirectory = "";
		
		string sharedDataFolder = "/usr/share/selene";
		string userDataFolder = homeDir + "/.config/selene";
		//string appPath = (File.new_for_path (arg0)).get_parent ().get_path ();

		ConfigDirectory = userDataFolder;
		ScriptsFolder_Official = sharedDataFolder + "/scripts";
		ScriptsFolder_Custom = userDataFolder + "/scripts";
		PresetsFolder_Official = sharedDataFolder + "/presets";
		PresetsFolder_Custom = userDataFolder + "/presets";
		SharedImagesFolder = sharedDataFolder + "/images";
		
		Utility.create_dir (this.ConfigDirectory);
		Utility.create_dir (this.ScriptsFolder_Custom);
		Utility.create_dir (this.PresetsFolder_Custom);

		// additional info
		
		log_msg ("Loading scripts from:\n'%s' (User Scripts)\n'%s' (Official Scripts)".printf(this.ScriptsFolder_Custom,this.ScriptsFolder_Official));
		log_msg ("Loading presets from:\n'%s' (User Presets)\n'%s' (Official Presets)".printf(this.PresetsFolder_Custom,this.PresetsFolder_Official));
		log_msg ("Using temp folder '%s'".printf(TempDirectory));

		// init config
		
		load_config ();
		
		// init regular expressions
		
		try{
			regex_generic = new Regex("""([0-9.]+)%""");
			regex_mkvmerge = new Regex("""Progress: ([0-9.]+)%""");
			regex_libav = new Regex("""time=[ ]*([0-9:.]+)""");
			
			//frame=   82 fps= 23 q=28.0 size=     133kB time=1.42 bitrate= 766.9kbits/s
			regex_libav_video = new Regex("""frame=[ ]*[0-9]+ fps=[ ]*([0-9]+)[.]?[0-9]* q=[ ]*[0-9]+[.]?[0-9]* size=[ ]*([0-9]+)kB time=[ ]*[0-9]+[.]?[0-9]* bitrate=[ ]*([0-9]+)[.]?[0-9]*""");
			
			//size=    1590kB time=30.62 bitrate= 425.3kbits/s  
			regex_libav_audio = new Regex("""size=[ ]*([0-9]+)kB time=[ ]*[0-9]+[.]?[0-9]* bitrate=[ ]*([0-9]+)[.]?[0-9]*""");
			
			//[53.4%] 1652/3092 frames, 24.81 fps, 302.88 kb/s, eta 0:00:58
			regex_x264 = new Regex("""\[[0-9]+[.]?[0-9]*%\] [0-9]+/[0-9]+ frames, ([0-9]+)[.]?[0-9]* fps, ([0-9]+)[.]?[0-9]* kb/s, eta ([0-9:.]+)""");
			
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
		}
		catch (Error e) {
			log_error (e.message);
		}
		
		blankLine = "";
		for (int i=0; i<80; i++)
			blankLine += " ";
	}
	
	public void start_input_thread ()
	{
		// start thread for reading user input
			
		try {
			Thread.create<void> (wait_for_user_input_thread, true);
		} catch (ThreadError e) {
			log_error (e.message);
		}
	}
	
	private void wait_for_user_input_thread ()
	{
		while (true){  // loop runs for entire application lifetime
			wait_for_user_input ();
		}
	}
	
	private void wait_for_user_input ()
	{
		int ch = stdin.getc ();

		if (WaitingForShutdown){
			Source.remove (shutdownTimerID);
			App.WaitingForShutdown = false;
			return;
		}
		else if ((ch == 'q')||(ch == 'Q')){
			if (this.Status == AppStatus.RUNNING){
				stop_batch ();
			}
		}
		else if ((ch == 'p')||(ch == 'P')){
			if (this.Status == AppStatus.RUNNING){
				pause ();
			}
		}
		else if ((ch == 'r')||(ch == 'R')){
			if (this.Status == AppStatus.PAUSED){
				resume ();
			}
		}
	}

	public MediaFile? find_input_file (string filePath)
	{
		foreach(MediaFile mf in this.InputFiles){
			if (mf.Path == filePath){
				return mf;
			}
		}
		
		return null;
	}
	
	public void save_config ()
	{
		var settings = new GLib.Settings ("apps.selene");
		settings.set_string ("backup-dir", BackupDirectory);
		settings.set_string ("output-dir", OutputDirectory);

		if (SelectedScript != null) {
			settings.set_string ("last-script", SelectedScript.Path);
		} else {
			settings.set_string ("last-script", "");
		}
	}
	
	public void load_config ()
	{
		var settings = new GLib.Settings ("apps.selene");
		string val;
		
		val = settings.get_string ("backup-dir");
		if (Utility.dir_exists(val))
			BackupDirectory = val;
		else
			BackupDirectory = "";
		
		val = settings.get_string ("output-dir");
		if (Utility.dir_exists(val))
			OutputDirectory = val;
		else 
			OutputDirectory = "";
		
		string sh = settings.get_string ("last-script");
		if (sh != null && sh.length > 0) {
			SelectedScript = new ScriptFile(sh);
		}
	}
	
	public void exit_app ()
	{
		save_config ();
		Gtk.main_quit ();
	}
	
	public bool add_file (string filePath)
	{
		MediaFile mFile = new MediaFile (filePath);
		if (mFile.IsValid) {
			InputFiles.add(mFile);
			log_msg ("File added: '%s'".printf (mFile.Path));
			return true;
		}
		else{
			log_error ("Unknown format: '%s'".printf (mFile.Path));
		}
		
		return false;
	}
	
	public void remove_files (Gee.ArrayList<MediaFile> file_list)
	{
		foreach(MediaFile mf in file_list){
			this.InputFiles.remove (mf);
			log_msg ("File removed: '%s'".printf (mf.Path));
		}
	}
	
	public void remove_all ()
	{
		this.InputFiles.clear();
		log_msg ("All files removed");
	}

	public void convert_begin ()
	{
		//check for empty list
		if (InputFiles.size == 0){
			log_error ("Input queue is empty! Please add some files.");
			return;
		}
		
		log_msg ("Starting batch of %d file(s):".printf(InputFiles.size), true);
		
		//check and create output dir
		if (this.OutputDirectory.length > 0) { 
			Utility.create_dir (this.OutputDirectory); 
			log_msg ("Files will be saved in '%s'".printf(this.OutputDirectory));
		}
		else{
			log_msg ("Files will be saved in source directory");
		}

		//check and create backup dir
		if (this.BackupDirectory.length > 0) { 
			Utility.create_dir (this.BackupDirectory); 
			log_msg ("Source files will be moved to '%s'".printf(this.BackupDirectory));
		}	
		
		//initialize batch control variables
		BatchStarted = true;
		BatchCompleted = false;
		Aborted = false;
		Status = AppStatus.RUNNING;
		
		//initialize file status
		foreach (MediaFile mf in InputFiles) {
			mf.Status = FileStatus.PENDING;
			mf.ProgressText = "Queued";
			mf.ProgressPercent = 0;
		}
		
		//if (ConsoleMode)
			//progressTimerID = Timeout.add (500, update_progress);
			
		//save config and begin
		save_config ();
		convert_next ();
	}
	
	private void convert_next ()
	{
		try {
			Thread.create<void> (convert_next_thread, true);
		} catch (ThreadError e) {
			log_error (e.message);
		}
	}

	private void convert_next_thread ()
	{
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
		}
		else{
			Status = AppStatus.IDLE;
			
			//handle shutdown for console mode
			if (ConsoleMode){
				if (Shutdown){
					log_msg ("System will shutdown in one minute!");
					log_msg ("Enter any key to Cancel...");
					shutdownTimerID = Timeout.add (60000, shutdown);
					WaitingForShutdown = true;
				}
				//exit app for console mode
				exit_app ();
			}
			
			//shutdown will be handled by GUI window for GUI-mode
		}
	}
	
	public void convert_finish ()
	{	
		//reset file status
		foreach(MediaFile mf in this.InputFiles) {
			mf.Status = FileStatus.PENDING;
			mf.ProgressText = "Queued";
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
	
	private bool convert_file (MediaFile mf)
	{
		bool retVal = false;
		
		if (Utility.file_exists (mf.Path) == false) { return false; }
		
		//prepare file
		CurrentFile = mf;
		CurrentFile.prepare (this.TempDirectory);		
		CurrentFile.Status = FileStatus.RUNNING;
		CurrentFile.ProgressText = null; // (not set) show value as percent
		CurrentFile.ProgressPercent = 0;
					
		log_msg ("Source: '%s'".printf(CurrentFile.Path), true);
		if (CurrentFile.SubFile != null){
			log_msg ("Subtitles: '%s'".printf(CurrentFile.SubName));
		}
		
		Progress = 0;
		StatusLine = "";
		CurrentLine = "";
		
		//convert file
		string scriptText = build_script (CurrentFile);
		string scriptPath = save_script (CurrentFile, scriptText);
		retVal = run_script (CurrentFile, scriptPath);
		
		//move files to backup location
		if ((BackupDirectory.length > 0) && (Utility.dir_exists (BackupDirectory))){
			Utility.move_file (CurrentFile.Path, BackupDirectory + "/" + CurrentFile.Name);
			if (CurrentFile.SubFile != null){
				Utility.move_file (CurrentFile.SubFile, BackupDirectory + "/" + CurrentFile.SubName);
			}
		}
		
		return retVal;
	}
	
	private string build_script (MediaFile mf)
	{
		var script = new StringBuilder ();
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
        
	    if (mf.SubFile != null){
			script.append ("subFile='" + escape (mf.SubFile) + "'\n");
			script.append ("subName='" + escape (mf.SubName) + "'\n");
			script.append ("subExt='" + escape (mf.SubExt.down()) + "'\n");
		}
		else {
			script.append ("subFile=''\n");
			script.append ("subName=''\n");
			script.append ("subExt=''\n");
		}
		script.append ("\n");
		script.append ("""scriptDir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"""");
		script.append ("\n");
		script.append ("cd \"$scriptDir\"\n");
		
		if (SelectedScript.Extension == ".sh") {

			// read and modify script template ---------------

			try {
				var fileScript = File.parse_name (SelectedScript.Path);
				var dis = new DataInputStream (fileScript.read ());

				MatchInfo match;
				Regex rxCrop_libav = new Regex ("""avconv.*-vf.*(crop=[^, ]+)""");
				Regex rxCrop_x264 = new Regex ("""x264.*(--vf|--video-filter).*(crop:[^/ ]+)""");
				Regex rxCrop_f2t = new Regex ("""ffmpeg2theora.*""");
				Regex rxCrop_f2t_left = new Regex ("""ffmpeg2theora.*(--cropleft [0-9]+) """);
				Regex rxCrop_f2t_right = new Regex ("""ffmpeg2theora.*(--cropright [0-9]+) """);
				Regex rxCrop_f2t_top = new Regex ("""ffmpeg2theora.*(--croptop [0-9]+) """);
				Regex rxCrop_f2t_bottom = new Regex ("""ffmpeg2theora.*(--cropbottom [0-9]+) """);
				
				string line = dis.read_line (null);
				while (line != null) {
					line = line.replace ("${audiodec}", """avconv -i "${inFile}" -f wav -acodec pcm_s16le -vn -y -""");
					
					if (mf.crop_enabled ()){
						if (rxCrop_libav.match (line, 0, out match)){
							line = line.replace (match.fetch(1), "crop=" + mf.crop_values_libav ());
						}
						else if (rxCrop_x264.match (line, 0, out match)){
							line = line.replace (match.fetch(2), "crop:" + mf.crop_values_x264 ());
						}
						else if (rxCrop_f2t.match (line, 0, out match)){
							if (rxCrop_f2t_left.match (line, 0, out match)){
								line = line.replace (match.fetch(1), "--cropleft " + mf.CropL.to_string());
							}
							if (rxCrop_f2t_right.match (line, 0, out match)){
								line = line.replace (match.fetch(1), "--cropright " + mf.CropR.to_string());
							}
							if (rxCrop_f2t_top.match (line, 0, out match)){
								line = line.replace (match.fetch(1), "--croptop " + mf.CropT.to_string());
							}
							if (rxCrop_f2t_bottom.match (line, 0, out match)){
								line = line.replace (match.fetch(1), "--cropbottom " + mf.CropB.to_string());
							}
						}
					}

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
			Utility.copy_file(SelectedScript.Path, mf.TempDirectory + "/preset.json");
		}
		
		script.append ("exitCode=$?\n");
		script.append ("echo ${exitCode} > ${exitCode}\n");
		return script.str;
	}
	
	private string escape (string txt)
	{
		return txt.replace ("'","'\\''");
	}
	
	private string save_script (MediaFile mf, string scriptText)
	{
		try{
			// create new script file
	        var file = File.new_for_path (mf.ScriptFile);
	        var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			var data_stream = new DataOutputStream (file_stream);
	        data_stream.put_string (scriptText);
	        data_stream.close();

	        // set execute permission
	        Utility.chmod (mf.ScriptFile, "u+x");
       	} 
	    catch (Error e) {
	        log_error (e.message);
	        return "";
	    }
	    
	    return mf.ScriptFile;
	}

	private bool run_script (MediaFile mf, string scriptFile)
	{
		bool retVal = false;
		
		if (ConsoleMode)
			log_msg ("Converting: Enter (q) to quit or (p) to pause...");
		else
			log_msg ("Converting...");
			
		//string scriptFile = CurrentFile.ScriptFile;
		//string audioTempFile = mFile.TempDir + "/audio.mka";
		//string videoTempFile = mFile.TempDir + "/video.mkv";
		
		string[] argv = new string[1];
		argv[0] = scriptFile;
		
		Pid child_pid;
		int input_fd;
		int output_fd;
		int error_fd;

		try {
			
			// execute script file
			
			Process.spawn_async_with_pipes(
			    null, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,   // child_setup
			    out child_pid,
			    out input_fd,
			    out output_fd,
			    out error_fd);
			    
			procID = child_pid;
			
			set_priority ();
			
			// create stream readers
			
			UnixInputStream uisOut = new UnixInputStream(output_fd, false);
			UnixInputStream uisErr = new UnixInputStream(error_fd, false);
			disOut = new DataInputStream(uisOut);
			disErr = new DataInputStream(uisErr);
			disOut.newline_type = DataStreamNewlineType.ANY;
			disErr.newline_type = DataStreamNewlineType.ANY;
			
			// create log file
			
	        var file = File.new_for_path (mf.LogFile);
	        var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			dsLog = new DataOutputStream (file_stream);
	        
        	// start another thread for reading error stream
        	
        	try {
			    Thread.create<void> (read_std_err, true);
		    } catch (Error e) {
		        log_error (e.message);
		    }
		    
		    // start reading output stream in current thread 
		    
		    outLine = disOut.read_line (null);
		   	while (outLine != null) {
		        CurrentLine = outLine.strip();
		        dsLog.put_string (outLine + "\n");
		        update_progress ();
		        outLine = disOut.read_line (null);
        	}
        	
        	Thread.usleep ((ulong) 0.1 * 1000000);
        	dsLog.close();
		}
		catch (Error e) {
			log_error (e.message);
		}	
        
        if (ConsoleMode){
	    	//remove the last status line
	    	stdout.printf ("\r%s\r", blankLine);
	    }
	    
	    if (Utility.file_exists (mf.TempDirectory + "/0")) {
			mf.Status = FileStatus.SUCCESS;
			mf.ProgressText = "Done";
			mf.ProgressPercent = 100;
			retVal = true;
			
			log_msg ("Completed");
			if (ShowNotificationPopups){
				Utility.notify_send ("File Completed", mf.Name, 2000, "low");
			}
		}
		else{
			mf.Status = FileStatus.ERROR;
			mf.ProgressText = "Error";
			mf.ProgressPercent = 0;
			retVal = false;
			
			log_msg ("Failed");
			if (ShowNotificationPopups){
				Utility.notify_send ("File Failed", mf.Name, 2000, "low");
			}
		}
			
	    
	    if (Aborted) {
	        log_msg ("Stopped!");
		}
		else {
			
		}

		// convert next file
		convert_next();
		
		return retVal;
	}

	private void read_std_err ()
	{
		try{
			errLine = disErr.read_line (null);
		    while (errLine != null) {
		        CurrentLine = errLine.strip();
		        dsLog.put_string (errLine + "\n");
		        update_progress ();
		        errLine = disErr.read_line (null);
			}
		}
		catch (Error e) {
			log_error (e.message);
		}	
	}
	
	public bool update_progress ()
	{		
		tempLine = App.CurrentLine;

		if ((tempLine == null)||(tempLine.length == 0)){ return true; }
		if (tempLine.index_of ("overread, skip") != -1){ return true; }
		if (tempLine.index_of ("Last message repeated") != -1){ return true; }
		
		if (regex_libav.match (tempLine, 0, out match)){
			dblVal = double.parse(match.fetch(1));
			Progress = (dblVal * 1000) / App.CurrentFile.Duration;

			if (regex_libav_video.match (tempLine, 0, out match)){
				StatusLine = "(avconv) %s fps, %s kbps, %s kb".printf(match.fetch(1), match.fetch(3), match.fetch(2));
			}
			else if (regex_libav_audio.match (tempLine, 0, out match)){
				StatusLine = "(avconv) %s kbps, %s kb".printf(match.fetch(2), match.fetch(1));
			}
			else {
				StatusLine = tempLine;
			}
		}
		else if (regex_ffmpeg2theora.match (tempLine, 0, out match)){
			dblVal = Utility.parse_time (match.fetch(1));
			Progress = (dblVal * 1000) / App.CurrentFile.Duration;
			StatusLine = "(ffmpeg2theora) %s+%s kbps".printf(match.fetch(2), match.fetch(3));
			if (regex_ffmpeg2theora2.match (tempLine, 0, out match)){
				StatusLine = "(ffmpeg2theora) %s+%s kbps, %s mb, eta %s".printf(match.fetch(2), match.fetch(3), match.fetch(5), match.fetch(4));
			}
			else {
				StatusLine = tempLine;
			}
		}
		else if (regex_ffmpeg2theora3.match (tempLine, 0, out match)){
			dblVal = Utility.parse_time (match.fetch(1));
			Progress = (dblVal * 1000) / App.CurrentFile.Duration;
			StatusLine = "(ffmpeg2theora) Scanning first pass, eta %s".printf(match.fetch(2));
		}
		else if (regex_opus.match (tempLine, 0, out match)){
			dblVal = Utility.parse_time (match.fetch(1));
			Progress = (dblVal * 1000) / App.CurrentFile.Duration;
			StatusLine = "(opusenc) %sx, %s kbps".printf(match.fetch(2), match.fetch(3));
		}
		else if (regex_vpxenc.match (tempLine, 0, out match)){
			dblVal = double.parse(match.fetch(2));
			Progress = dblVal / App.CurrentFile.OutputFrameCount;
			StatusLine = "(vpxenc) %s, %s frames, %.0f kb".printf(match.fetch(1), match.fetch(2), double.parse(match.fetch(3))/1000);
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
		}
		
		CurrentFile.ProgressPercent = (int)(Progress * 100);

		if (ConsoleMode){
			stdout.printf ("\r%s\r", blankLine[0:78]);
			if (Status == AppStatus.RUNNING){
				if (StatusLine.length > 70)
					stdout.printf ("\r[%3.0f%%] %-72s", (Progress*100), StatusLine[0:70]);
				else
					stdout.printf ("\r[%3.0f%%] %-72s", (Progress*100), StatusLine);
			}
			stdout.flush ();
		}
		
		return true;
	}
	
	public void stop_batch ()
	{
		// we need to un-freeze the processes before we kill them
		if (this.Status == AppStatus.PAUSED){
			resume ();	
		}
		
		this.Aborted = true;
		for(int k = InputFiles.index_of(CurrentFile); k < InputFiles.size; k++)
		{
			MediaFile mf  = InputFiles[k];
			mf.ProgressText = "Cancelled";
		}
		
	    Utility.process_kill (procID);
	}
	
	public void stop_file ()
	{
		// we need to un-freeze the processes before we kill them
		if (this.Status == AppStatus.PAUSED){
			resume ();	
		}
		
		// this.Aborted = true; //Do not set Abort flag
		CurrentFile.Status = FileStatus.SKIPPED;
		CurrentFile.ProgressText = "Cancelled";

	    Utility.process_kill (procID);
	}
	
	public void pause ()
	{
		Pid childPid;
	    foreach (long pid in Utility.get_process_children (procID)){
		    childPid = (Pid) pid;
		    Utility.process_pause (childPid);
	    }
		
		Status = AppStatus.PAUSED;
		CurrentFile.ProgressText = "Paused";
		
		if (ConsoleMode)
			log_msg ("Paused: Enter (r) to resume...");
		else
			log_msg ("Paused");
	}
	
	public void resume ()
	{
		Pid childPid;
	    foreach (long pid in Utility.get_process_children (procID)){
		    childPid = (Pid) pid;
		    Utility.process_resume (childPid);
	    }
	    
		Status = AppStatus.RUNNING;
		CurrentFile.ProgressText = null;
	    
	    if (ConsoleMode)
			log_msg ("Converting: Enter (q) to quit or (p) to pause...");
		else
			log_msg ("Converting...");
	}
	
	public void set_priority ()
	{
		int prio = 0;
		if (BackgroundMode) { prio = 5; }
		
		Pid appPid = Posix.getpid ();
		Utility.process_set_priority (appPid, prio);
		
		if (Status == AppStatus.RUNNING){
			Utility.process_set_priority (procID, prio);
			
			Pid childPid;
		    foreach (long pid in Utility.get_process_children (procID)){
			    childPid = (Pid) pid;
			    
			    if (BackgroundMode)
		    		Utility.process_set_priority (childPid, prio);
		    	else
		    		Utility.process_set_priority (childPid, prio);
		    }
		}
	}

	private bool shutdown ()
	{
		Utility.shutdown ();
		return true;
	}
	
	private string get_preset_commandline (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		//Json.Object subs = (Json.Object) settings.get_object_member("subtitle");
		
		//insert temporary file names ------------
		
		s += "\n";
		s += "outputFile=\"${outDir}/${title}" + general.get_string_member("extension") + "\"\n";
		s += "tempVideo=\"${tempDir}/video" + general.get_string_member("extension") + "\"\n";
		switch (audio.get_string_member("codec")) {
			case "mp3lame":
				s += "tempAudio=\"${tempDir}/audio.mp3\"\n";
				break;
			case "neroaac":
				s += "tempAudio=\"${tempDir}/audio.mp4\"\n";
				break;
			case "vorbis":
				s += "tempAudio=\"${tempDir}/audio.ogg\"\n";
				break;
			case "opus":
				s += "tempAudio=\"${tempDir}/audio.opus\"\n";
				break;
		}
		s += "\n";
		
		//create command line --------------
		
		string format = general.get_string_member("format");
		string acodec = audio.get_string_member("codec");
		string vcodec = video.get_string_member("codec");
		
		switch (format)
		{
			case "mkv":
			case "mp4v":
			case "webm":
				//encode video
				switch (vcodec)
				{
					case "x264":
						s += encode_video_x264(mf,settings);
						break;
					case "vp8":
						s += encode_video_vpxenc(mf,settings);
						break;
				}
				
				//encode audio
				if (mf.HasAudio && acodec != "disable") {
					switch (acodec) {
						case "mp3lame":
							s += encode_audio_mp3lame(mf,settings);
							break;
						case "neroaac":
							s += encode_audio_neroaac(mf,settings);
							break;
						case "vorbis":
							s += encode_audio_oggenc(mf,settings);
							break;
					}
				}
				
				//mux audio, video and subs
				switch (format){
					case "mkv":
					case "webm":
						s += mux_mkvmerge(mf,settings);
						break;
					case "mp4v":
						s += mux_mp4box(mf,settings);
						break;
				}
					
				break;
			
			case "ogv":
				s += encode_video_ffmpeg2theora(mf,settings);
				break;
				
			case "mp3":
				s += encode_audio_mp3lame(mf,settings);
				break;
				
			case "mp4a":
				s += encode_audio_neroaac(mf,settings);
				break;
				
			case "opus":
				s += encode_audio_opus(mf,settings);
				break;
				
			case "ogg":
				s += encode_audio_oggenc(mf,settings);
				break;

			case "ac3":
			case "flac":
			case "wav":
				s += encode_audio_avconv(mf,settings);
				break;
		}
		
		s += "\n";
		
		//set output file path
		string outpath = "";
		if (OutputDirectory.length == 0){
      		outpath = mf.Location;
      	} else{
	      	outpath = OutputDirectory;
	    }
		mf.OutputFilePath = outpath + "/" + mf.Title + general.get_string_member("extension") ;
		
		return s;
	}
	
	private string encode_video_x264 (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");

		bool usePiping = true;
		if (video.get_string_member("fpsNum") == "0" && video.get_string_member("fpsDenom") == "0") {
			usePiping = false;
		}
		
		if (usePiping) {
			s += "avconv -i \"${inFile}\" -copyinkf -an -f rawvideo -vcodec rawvideo -pix_fmt yuv420p";

			int fpsNum = int.parse(video.get_string_member("fpsNum"));
			int fpsDenom = int.parse(video.get_string_member("fpsDenom"));
			if (fpsNum != 0 && fpsDenom != 0) {
				s += " -r %d/%d".printf(fpsNum,fpsDenom);
				mf.OutputFrameCount = (long)((mf.Duration / 1000.0) * ((float)fpsNum/fpsDenom));
			}
		
			s += " -y - | ";
		}
		
		s += "x264";
		
		if (video.get_string_member("mode") == "2pass"){
			s += " --pass {passNumber}"; 
		}
		
		s += " --preset " + video.get_string_member("preset");
		s += " --profile " + video.get_string_member("profile");
		
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
		
		//---------------
		
		//other options
		if (video.get_string_member("options").strip() != "") {
			s += " " +  video.get_string_member("options").strip();
		}
				
		//add output file path placeholder
		s += " -o {outputFile}";
		
		/*//determine output file path
		string finalOutput = "";
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			//encode to tempVideo
			finalOutput = "\"${tempVideo}\"";
		}
		else {
			//encode to outputFile
			finalOutput = "\"${outputFile}\"";
		}*/
		
		if (usePiping) {
			//encode from StdInput
			s += " -";
			s += " --input-res %dx%d".printf(mf.SourceWidth, mf.SourceHeight); //TODO: Resizing should be done by x264
			s += " --fps %s/%s".printf(video.get_string_member("fpsNum"), video.get_string_member("fpsDenom"));
		}
		else {
			//encode from input file
			s += " \"${inFile}\"";
		}

		s += "\n";
		
		if (video.get_string_member("mode") == "2pass"){
			string temp = s.replace("{passNumber}","1").replace("{outputFile}","/dev/null");
			temp += s.replace("{passNumber}","2").replace("{outputFile}","\"${tempVideo}\"");
			s = temp;
		}
		else
		{
			s = s.replace("{outputFile}","\"${tempVideo}\"");
		}
		
		return s;
	}
	
	private string encode_video_ffmpeg2theora (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");
		
		s += "ffmpeg2theora";
		s += " \"${inFile}\"";

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
	}
	
	/*
	private string encode_video_avconv (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");
		
		s += "avconv";
		s += " -i \"${inFile}\"";
		s += " -f " + general.get_string_member("format");
		s += " -an -sn -c:v libvpx";

		if (video.get_string_member("mode") == "2pass"){
			s += " -pass {passNumber}"; 
		}
		
		string kbps = video.get_string_member("bitrate");
		switch(video.get_string_member("mode")){
			case "vbr":
			case "2pass":
				s += " -b:v %sk".printf(kbps);
				break;
			case "cbr":
				s += " -minrate %sk -maxrate %sk -b:v %sk".printf(kbps,kbps,kbps);
				break;
			case "cq":
				s += " -crf %s".printf(video.get_string_member("quality"));
				break;
		}
		
		s += " -deadline " + video.get_string_member("speed");
		
		// filters ----------
		
		//fps
		if (video.get_string_member("fpsNum") != "0" && video.get_string_member("fpsDenom") != "0") {
			s += " -r " + video.get_string_member("fpsNum") + "/" + video.get_string_member("fpsDenom");
		}
		
		string vf = "";
		
		//cropping
		if (mf.crop_enabled()) {
			vf += ",crop=%s".printf(mf.crop_values_libav());
		}

		//resizing
		int w,h;
		bool rescale = calculate_video_resolution(mf, settings, out w, out h);
		if (rescale) {
			vf += ",scale=%d:%d".printf(w,h);
		}

		if (vf.length > 0){
			s += " -vf " + vf[1:vf.length];
		}
		
		//---------------
		
		//other options
		if (video.get_string_member("options").strip() != "") {
			s += " " +  video.get_string_member("options").strip();
		}
				
		//add output file path placeholder
		s += " -y {outputFile}";
		
		s += "\n";
		
		if (video.get_string_member("mode") == "2pass"){
			string temp = s.replace("{passNumber}","1").replace("{outputFile}","/dev/null");
			temp += s.replace("{passNumber}","2").replace("{outputFile}","\"${tempVideo}\"");
			s = temp;
		}
		else
		{
			s = s.replace("{outputFile}","\"${tempVideo}\"");
		}
		
		return s;
	}
*/

	private string encode_video_vpxenc (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");
		
		s += decode_video_avconv(mf,settings,true);
		s += "vpxenc";

		if (video.get_string_member("mode") == "2pass"){
			s += " --passes=2 --pass={passNumber} --fpf=stats"; 
		}
		
		string vquality = "%.0f".printf(double.parse(video.get_string_member("quality")));
		switch(video.get_string_member("mode")){
			case "vbr":
			case "2pass":
				s += " --end-usage=vbr --target-bitrate=" + video.get_string_member("bitrate");
				break;
			case "cbr":
				s += " --end-usage=cbr --target-bitrate=" + video.get_string_member("bitrate");
				break;
			case "cq":
				s += " --end-usage=cq --cq-level=" + vquality;
				break;
		}
		
		s += " --good";
		switch(video.get_string_member("speed")){
			case "good_0":
				s += " --cpu-used=0";
				break;
			case "good_1":
				s += " --cpu-used=1";
				break;
			case "good_2":
				s += " --cpu-used=2";
				break;
			case "good_3":
				s += " --cpu-used=3";
				break;
			case "good_4":
				s += " --cpu-used=4";
				break;
			case "good_5":
				s += " --cpu-used=5";
				break;
		}

		//---------------
		
		//other options
		if (video.get_string_member("options").strip() != "") {
			s += " " +  video.get_string_member("options").strip();
		}
		
		//specify input dimensions (required)
		int w,h;
		calculate_video_resolution(mf, settings, out w, out h);
		s += " --width=%d --height=%d".printf(w,h);
			
		//output
		s += " -o {outputFile}";
		
		//input
		s += " -";

		s += "\n";
		
		if (video.get_string_member("mode") == "2pass"){
			string temp = s.replace("{passNumber}","1").replace("{outputFile}","/dev/null");
			temp += s.replace("{passNumber}","2").replace("{outputFile}","\"${tempVideo}\"");
			s = temp;
		}
		else
		{
			s = s.replace("{outputFile}","\"${tempVideo}\"");
		}
		
		return s;
	}
	
	private bool calculate_video_resolution (MediaFile mf, Json.Object settings, out int OutputWidth, out int OutputHeight)
	{
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
	
	private string encode_audio_mp3lame (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		
		s += decode_audio_avconv(mf, settings, false);
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
		s += " -";
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " \"${tempAudio}\"";
		}
		else {
			//encode to outputFile
			s += " \"${outputFile}\"";
		}
		s += "\n";
		
		return s;
	}
	
	private string encode_audio_neroaac (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		
		s += decode_audio_avconv(mf, settings, false);
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
		s += " -if -";
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " -of \"${tempAudio}\"";
		}
		else {
			//encode to outputFile
			s += " -of \"${outputFile}\"";
		}
		s += "\n";
		
		return s;
	}
	
	private string encode_audio_opus (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		
		s += decode_audio_avconv(mf, settings, true);
		s += "opusenc";
		s += " --bitrate " + audio.get_string_member("bitrate");
		//options
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
			s += " \"${tempAudio}\"";
		}
		else {
			//encode to outputFile
			s += " \"${outputFile}\"";
		}
		s += "\n";
		
		return s;
	}
	
	private string encode_audio_avconv (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		Json.Object general = (Json.Object) settings.get_object_member("general");
		//Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");

		string format = general.get_string_member("format");
		
		s += "avconv";
		s += " -i \"${inFile}\"";
		
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
		
		s += " -vn -sn";
		s += " -y \"${outputFile}\"";
		
		return s;
	}
	
	private string encode_audio_oggenc (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");
		
		s += decode_audio_avconv(mf, settings, true);
		s += "oggenc --quiet";
		
		//mode
		switch (audio.get_string_member("mode")){
			case "vbr":
				s += " --bitrate " + audio.get_string_member("bitrate");
				break;
			case "abr":
				s += " --quality " + audio.get_string_member("quality");
				break;
		}
		
		//subs
		if (subs.get_string_member("mode") == "embed") {
			if (mf.SubExt == ".srt" || mf.SubExt == ".lrc") {
				s += " --lyrics \"${subFile}\"";
			}
		}

		//output
		if (mf.HasVideo && video.get_string_member("codec") != "disable") {
			//encode to tempAudio
			s += " --output \"${tempAudio}\"";
		}
		else {
			//encode to outputFile
			s += " --output \"${outputFile}\"";
		}
		
		//input
		s += " -";
		
		s += "\n";
		
		return s;
	}

	private string decode_video_avconv (MediaFile mf, Json.Object settings, bool silent)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		Json.Object video = (Json.Object) settings.get_object_member("video");
		//Json.Object audio = (Json.Object) settings.get_object_member("audio");
		//Json.Object subs = (Json.Object) settings.get_object_member("subtitle");
		
		s += "avconv";
		
		//progress info
		if (silent){
			s += " -nostats";
		}
		//input
		s += " -i \"${inFile}\"";
		
		//format
		s += " -f rawvideo -vcodec rawvideo -pix_fmt yuv420p";
		
		//fps
		int fpsNum = int.parse(video.get_string_member("fpsNum"));
		int fpsDenom = int.parse(video.get_string_member("fpsDenom"));
		if (fpsNum != 0 && fpsDenom != 0) {
			s += " -r %d/%d".printf(fpsNum,fpsDenom);
			mf.OutputFrameCount = (long)((mf.Duration / 1000.0) * ((float)fpsNum/fpsDenom));
		}
		
		string vf = "";
		
		//cropping
		if (mf.crop_enabled()) {
			vf += ",crop=%s".printf(mf.crop_values_libav());
		}

		//resizing
		int w,h;
		bool rescale = calculate_video_resolution(mf, settings, out w, out h);
		if (rescale) {
			vf += ",scale=%d:%d".printf(w,h);
		}

		if (vf.length > 0){
			s += " -vf " + vf[1:vf.length];
		}
		
		//---------------
		
		//output
		s += " -an -sn -y - | ";
		
		return s;
	}
	
	private string decode_audio_avconv(MediaFile mf, Json.Object settings, bool silent)
	{
		string s = "";
		
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		string acodec = audio.get_string_member("codec");

		s += "avconv";
		
		//progress info
		if (silent){
			s += " -nostats";
		}
		//input
		s += " -i \"${inFile}\"";
		
		//format
		s += " -f wav -acodec pcm_s16le";
		
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
		
		//output
		s += " -vn -y - | ";
		
		return s;
	}
	
	private string mux_mkvmerge (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		Json.Object general = (Json.Object) settings.get_object_member("general");
		//Json.Object video = (Json.Object) settings.get_object_member("video");
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
		
		//add video
		s += " --compression -1:none \"${tempVideo}\"";
		
		//add audio
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			s += " --compression -1:none \"${tempAudio}\"";
		}
		
		//add subs
		if (format != "webm") {
			if (subs.get_string_member("mode") == "embed") {
				if (mf.SubExt == ".srt" || mf.SubExt == ".sub" || mf.SubExt == ".ssa") {
					s += " --compression -1:none \"${subFile}\"";
				}
			}
		}
		else{
			//WebM currently does not support subtitles
		}
		
		s += "\n";
		
		return s;
	}
	
	private string mux_mp4box (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		//Json.Object general = (Json.Object) settings.get_object_member("general");
		//Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		Json.Object subs = (Json.Object) settings.get_object_member("subtitle");

		s += "MP4Box -new";
		
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			s += " -add \"${tempAudio}\"";
		}
		
		s += " -add \"${tempVideo}\"";
		
		if (subs.get_string_member("mode") == "embed") {
			if (mf.SubExt == ".srt" || mf.SubExt == ".sub" || mf.SubExt == ".ttxt" || mf.SubExt == ".xml"){
				s += " -add \"${subFile}\"";
			}
		}
		
		s += " \"${outputFile}\"";
		s += "\n";
		
		return s;
	}
	
	private string mux_avconv (MediaFile mf, Json.Object settings)
	{
		string s = "";
		
		Json.Object general = (Json.Object) settings.get_object_member("general");
		//Json.Object video = (Json.Object) settings.get_object_member("video");
		Json.Object audio = (Json.Object) settings.get_object_member("audio");
		string format = general.get_string_member("format");
		
		s += "avconv ";
		if (mf.HasAudio && audio.get_string_member("codec") != "disable") {
			s += " -i \"${tempAudio}\"";
		}
		s += " -i \"${tempVideo}\"";
		
		/*TODO: Mux SRT
		 * if (mf.SubExt == ".srt" || mf.SubExt == ".sub" || mf.SubExt == ".ssa"){
			s += " --compression -1:none \"${subFile}\"";
		}
		* */
		
		switch(format){
			case "mp4v":
				s += " -f mp4";
				break;
		}
		s += " -c:a copy -c:v copy -sn";
		s += " -y \"${outputFile}\"";
		s += "\n";
		
		return s;
	}
}


