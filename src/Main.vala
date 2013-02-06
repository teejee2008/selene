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

public Main App;
public const string AppName = "Selene Media Encoder";
public const string AppVersion = "1.1";
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
	public int V_Width = 0;
	public int V_Height = 0;
	
	public string ScriptFile;
	public string TempDirectory;
	public string LogFile;
	
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
		            if (fname.has_prefix(Title.down()) && (fname.has_suffix (".srt")||fname.has_suffix (".sub")||fname.has_suffix (".ssa")))
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
							log_msg	("%ld".printf(Duration));
							break;
					}
				}
				else if (sectionType == "video"){
					switch (key.down ()) {
						case "width":
							V_Width = int.parse(val.replace ("pixels","").replace (" ","").strip ());
							break;
						case "height":
							V_Height = int.parse(val.replace ("pixels","").replace (" ","").strip ());
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
		Utility.create_dir (this.TempDirectory);
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
		
		CropR = V_Width - CropW - CropL;
		CropB = V_Height - CropH - CropT;
		
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
}

public class Main : GLib.Object
{
	public Gee.ArrayList<MediaFile> InputFiles;
	public Gee.ArrayList<ScriptFile> ScriptFiles;

	public string DataDirectory;
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
	public bool Installed = false;
	public bool ShowNotificationPopups = false;
	
	private Regex regex_generic;
	private Regex regex_mkvmerge;
	private Regex regex_libav;
	private Regex regex_libav_video;
	private Regex regex_libav_audio;
	private Regex regex_x264;
	private Regex regex_ffmpeg2theora;
	private Regex regex_ffmpeg2theora2;
	
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
						if (App.select_script(args[k]) == false) {
							return 1;
						}
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
		ScriptFiles = new Gee.ArrayList<ScriptFile>();
		
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
		
		// check if app is installed
		
		string sharePath = "/usr/share/selene/scripts";
		string appPath = (File.new_for_path (arg0)).get_parent ().get_path ();

		if (Utility.dir_exists (appPath + "/selene-scripts"))
			this.Installed = false;
		else
			this.Installed = true;
		
		// Set Data & Config dir paths -------		
		
		if (Installed){
			this.ConfigDirectory = homeDir + "/.config/selene";
			this.DataDirectory = homeDir + "/.config/selene/scripts";
		}
		else{
			this.ConfigDirectory = appPath;
			this.DataDirectory = appPath + "/selene-scripts";
		}

		Utility.create_dir (this.ConfigDirectory);
		Utility.create_dir (this.DataDirectory);

		// load scripts
		
		reload_scripts ();

		// check if script dir is empty
		
		if (this.ScriptFiles.size == 0){
			if (Utility.dir_exists (sharePath)){
				
				// copy installed scripts
				
				log_msg ("Script directory is empty!");
				log_msg ("Copying scripts from '%s'".printf (sharePath));
				
				try{
					var dataDir = File.parse_name (sharePath);
					var enumerator = dataDir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
					FileInfo fileInfo;
					
					while ((fileInfo = enumerator.next_file ()) != null){
						if (fileInfo.get_name().down().has_suffix(".sh")){
							File file = File.new_for_path (sharePath + "/" + fileInfo.get_name());
							Utility.copy_file (file.get_path(), this.DataDirectory + "/" + file.get_basename());
						}
					}
				}
				catch (Error e) {
					log_error (e.message);
				}
				
				reload_scripts ();
			}
		}
		
		// additional info
		
		log_msg ("Loading scripts from '%s'".printf(DataDirectory));
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
			regex_ffmpeg2theora = new Regex ("""([0-9]+[:][0-9]+[:][0-9]+[.]?[0-9]*) audio: ([0-9]+)kbps video: ([0-9]+)kbps""");
			//  0:00:01.16 audio: 54kbps video: 396kbps, ET: 00:22:56, est. size: 85.1 MB
			regex_ffmpeg2theora2 = new Regex ("""([0-9]+[:][0-9]+[:][0-9]+[.]?[0-9]*) audio: ([0-9]+)kbps video: ([0-9]+)kbps, ET: ([0-9]+[:][0-9]+[:][0-9]+[.]?[0-9]*), est. size: ([0-9]+[.]?[0-9]* [a-zA-Z]*)""");
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

	public void reload_scripts ()
	{
		try
		{
			var dataDir = File.parse_name (DataDirectory);
	        var enumerator = dataDir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
	
	        FileInfo file;
	        while ((file = enumerator.next_file ()) != null) {
		        add_script (DataDirectory + "/" + file.get_name());
	        } 
        }
        catch(Error e){
	        log_error (e.message);
	    }
	}
	
	public bool select_script (string scriptFile)
	{
		// check if only script name has been specified
		if (scriptFile.index_of ("/") == -1) {
			string sh = DataDirectory + "/" + scriptFile;
			if (sh.down().has_suffix(".sh") == false){
				sh = sh + ".sh";
			}

			if (Utility.file_exists (sh)){
				SelectedScript = find_script(sh);
				if (SelectedScript == null){
					SelectedScript = add_script (sh);
				}
				return true;
			}
		}
		
		// resolve the full path and check
		string filePath = Utility.resolve_relative_path(scriptFile);
		SelectedScript = find_script(filePath);
		if (SelectedScript == null){
			SelectedScript = add_script (filePath);
		}
		
		if (SelectedScript == null){
			log_error ("Script file not found!");
			return false;
		}
		else{
			log_msg ("Selected Script: '%s'".printf (SelectedScript.Path));
			return true;
		}
	}
	
	public ScriptFile? add_script (string filePath)
	{
		try{
			if (Utility.file_exists(filePath) == false) {
				return null;
			}
			
			File file = File.parse_name (filePath);
			FileInfo finfo = file.query_info ("*", FileQueryInfoFlags.NONE, null);
			string fname = finfo.get_name().down();
            if (fname.has_suffix (".sh"))
            {	
	            ScriptFile sh = new ScriptFile() ;
	            sh.Path = filePath;
	            sh.Name = finfo.get_name();
	            sh.Title = sh.Name[0:sh.Name.length - 3];
	            
	            this.ScriptFiles.add(sh);
	            return sh;
            }
        }
        catch(Error e){
	        log_error (e.message);
	    }
	    
        return null;
	}
	
	public ScriptFile? find_script (string filePath)
	{
		foreach(ScriptFile sh in this.ScriptFiles){
			if (sh.Path == filePath){
				return sh;
			}
		}
		
		return null;
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
			select_script(sh);
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
		if (InputFiles.size == 0){
			log_error ("Input queue is empty! Please add some files.");
			return;
		}
		
		log_msg ("Starting batch of %d file(s):".printf(InputFiles.size), true);

		if (this.OutputDirectory.length > 0) { 
			Utility.create_dir (this.OutputDirectory); 
			log_msg ("Files will be saved in '%s'".printf(this.OutputDirectory));
		}
		else{
			log_msg ("Files will be saved in source directory");
		}
		
		if (this.BackupDirectory.length > 0) { 
			Utility.create_dir (this.BackupDirectory); 
			log_msg ("Source files will be moved to '%s'".printf(this.BackupDirectory));
		}	
		
		BatchStarted = true;
		BatchCompleted = false;
		Aborted = false;
		Status = AppStatus.RUNNING;
		
		//if (ConsoleMode)
			//progressTimerID = Timeout.add (500, update_progress);
			
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
		
		foreach (MediaFile mf in InputFiles) {
			if (mf.Status == FileStatus.PENDING){
				nextFile = mf;
				break;
			}
		}
			
		if (!Aborted && nextFile != null){
			convert_file(nextFile);
		}
		else{
			Status = AppStatus.IDLE;
		}
	}
	
	public void convert_finish ()
	{
		foreach(MediaFile mf in this.InputFiles) {
			mf.Status = FileStatus.PENDING;
			mf.ProgressText = "Queued";
			mf.ProgressPercent = 0;
		}
		
		//if (ConsoleMode)
			//Source.remove (progressTimerID);

		save_config ();
		
		if (ConsoleMode){
			if (Shutdown){
				log_msg ("System will shutdown in one minute!");
				log_msg ("Enter any key to Cancel...");
				shutdownTimerID = Timeout.add (60000, shutdown);
				WaitingForShutdown = true;
			}
			exit_app ();
		}
		
		BatchStarted = true;
		BatchCompleted = true;
		Aborted = false;
		Status = AppStatus.NOTSTARTED;
	}
	
	private bool convert_file (MediaFile mf)
	{
		bool retVal = false;
		
		if (Utility.file_exists (mf.Path) == false) { return false; }
		
		// prepare 
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
		
		// convert file
		
		string script = build_script ();
		save_script (script);
		retVal = run_script ();
		
		// move input files to backup location
		
		if ((BackupDirectory.length > 0) && (Utility.dir_exists (BackupDirectory))){
			Utility.move_file (CurrentFile.Path, BackupDirectory + "/" + CurrentFile.Name);
			if (CurrentFile.SubFile != null){
				Utility.move_file (CurrentFile.SubFile, BackupDirectory + "/" + CurrentFile.SubName);
			}
		}
		
		return retVal;
	}
	
	private string build_script ()
	{
		var script = new StringBuilder ();
		script.append ("#!/bin/bash\n");
		script.append ("\n");
		
		// insert variables -----------------
      
      	script.append ("tempDir='" + escape (CurrentFile.TempDirectory) + "'\n");
      	script.append ("inDir='" + escape (CurrentFile.Location) + "'\n");
      	if (OutputDirectory.length == 0){
      		script.append ("outDir='" + escape (CurrentFile.Location) + "'\n");
      	} else{
	      	script.append ("outDir='" + escape (OutputDirectory) + "'\n");
	    }
      	script.append ("logFile='" + escape (CurrentFile.LogFile) + "'\n");
      	script.append ("\n");
        script.append ("inFile='" + escape (CurrentFile.Path) + "'\n");
        script.append ("name='" + escape (CurrentFile.Name) + "'\n");
        script.append ("title='" + escape (CurrentFile.Title) + "'\n");
        script.append ("ext='" + escape (CurrentFile.Extension) + "'\n");
        script.append ("duration='" + escape ("%.0f".printf(CurrentFile.Duration / 1000)) + "'\n");
        script.append ("hasAudio=" + (CurrentFile.HasAudio ? "1" : "0") + "\n");
        script.append ("hasVideo=" + (CurrentFile.HasVideo ? "1" : "0") + "\n");
        script.append ("\n");
        
	    if (CurrentFile.SubFile != null){
			script.append ("subFile='" + escape (CurrentFile.SubFile) + "'\n");
			script.append ("subName='" + escape (CurrentFile.SubName) + "'\n");
			script.append ("subExt='" + escape (CurrentFile.SubExt) + "'\n");
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
		
		// read script template ---------------

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
		        
		        if (CurrentFile.crop_enabled ()){
					if (rxCrop_libav.match (line, 0, out match)){
						line = line.replace (match.fetch(1), "crop=" + CurrentFile.crop_values_libav ());
					}
					else if (rxCrop_x264.match (line, 0, out match)){
						line = line.replace (match.fetch(2), "crop:" + CurrentFile.crop_values_x264 ());
					}
					else if (rxCrop_f2t.match (line, 0, out match)){
						if (rxCrop_f2t_left.match (line, 0, out match)){
							line = line.replace (match.fetch(1), "--cropleft " + CurrentFile.CropL.to_string());
						}
						if (rxCrop_f2t_right.match (line, 0, out match)){
							line = line.replace (match.fetch(1), "--cropright " + CurrentFile.CropR.to_string());
						}
						if (rxCrop_f2t_top.match (line, 0, out match)){
							line = line.replace (match.fetch(1), "--croptop " + CurrentFile.CropT.to_string());
						}
						if (rxCrop_f2t_bottom.match (line, 0, out match)){
							line = line.replace (match.fetch(1), "--cropbottom " + CurrentFile.CropB.to_string());
						}
					}
		        }

		        script.append (line + "\n");
		        line = dis.read_line (null);
	        }
	    } catch (Error e) {
	        log_error (e.message);
	    }
		
		script.append ("exitCode=$?\n");
		script.append ("echo ${exitCode} > ${exitCode}\n");
		return script.str;
	}
	
	private string escape (string txt)
	{
		return txt.replace ("'","'\\''");
	}
	
	private bool save_script (string scriptText)
	{
		try{
			// create new script file
	        var file = File.new_for_path (CurrentFile.ScriptFile);
	        var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			var data_stream = new DataOutputStream (file_stream);
	        data_stream.put_string (scriptText);
	        data_stream.close();

	        // set execute permission
	        Utility.chmod (CurrentFile.ScriptFile, "u+x");
       	} 
	    catch (Error e) {
	        log_error (e.message);
	        return false;
	    }
	    
	    return true;
	}

	private bool run_script ()
	{
		bool retVal = false;
		
		if (ConsoleMode)
			log_msg ("Converting: Enter (q) to quit or (p) to pause...");
		else
			log_msg ("Converting...");
			
		string scriptFile = CurrentFile.ScriptFile;
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
			
	        var file = File.new_for_path (CurrentFile.LogFile);
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
	    
        if (Aborted)
	        log_msg ("Stopped!");
	    else{
		    log_msg ("Done");
		    if (ShowNotificationPopups)
				Utility.notify_send ("File Complete", CurrentFile.Name, 2000, "low");
		}
		
		// check for errors
        if (Utility.file_exists (CurrentFile.TempDirectory + "/0"))
        {
			CurrentFile.Status = FileStatus.SUCCESS;
			CurrentFile.ProgressText = "Done";
			CurrentFile.ProgressPercent = 100;
			retVal = true;
		}
		else
		{
			CurrentFile.Status = FileStatus.ERROR;
			CurrentFile.ProgressText = "Error";
			CurrentFile.ProgressPercent = 0;
			retVal = false;
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
		if (tempLine == null){ return true; }
		
		if (tempLine.index_of ("overread, skip") != -1){ return true; }
		if (tempLine.index_of ("Last message repeated") != -1){ return true; }
		
		StatusLine = tempLine;

		if (regex_generic.match (tempLine, 0, out match)){
			dblVal = double.parse(match.fetch(1));
			Progress = dblVal / 100;

			if (regex_mkvmerge.match (tempLine, 0, out match)){
				StatusLine = "(mkvmerge) %.0f %%".printf(Progress * 100);
			}
			else if (regex_x264.match (tempLine, 0, out match)){
				StatusLine = "(x264) %s fps, %s kbps, eta %s".printf(match.fetch(1),match.fetch(2),match.fetch(3));
			}
		}
		else if (regex_libav.match (tempLine, 0, out match)){
			dblVal = double.parse(match.fetch(1));
			Progress = (dblVal * 1000) / App.CurrentFile.Duration;

			if (regex_libav_video.match (tempLine, 0, out match)){
				StatusLine = "(avconv) %s fps, %s kbps, %s kb".printf(match.fetch(1), match.fetch(3), match.fetch(2));
			}
			else if (regex_libav_audio.match (tempLine, 0, out match)){
				StatusLine = "(avconv) %s kbps, %s kb".printf(match.fetch(2), match.fetch(1));
			}
		}
		else if (regex_ffmpeg2theora.match (tempLine, 0, out match)){
			dblVal = Utility.parse_time (match.fetch(1));
			Progress = (dblVal * 1000) / App.CurrentFile.Duration;
			StatusLine = "(ffmpeg2theora) %s+%s kbps".printf(match.fetch(2), match.fetch(3));
			if (regex_ffmpeg2theora2.match (tempLine, 0, out match)){
				StatusLine = "(ffmpeg2theora) %s+%s kbps, %s, eta %s".printf(match.fetch(2), match.fetch(3), match.fetch(5), match.fetch(4));
			}
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
	
}


