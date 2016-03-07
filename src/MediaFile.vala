using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class MediaFile : GLib.Object{
	public string Path;
	public string Name;
	public string Title;
	public string Extension;
	public string Location;

	public int64 Size = 0;
	public long Duration = 0; //in milliseconds
	public string ThumbnailImagePath = "";

	public string SubFile = "";
	public string SubName = "";
	public string SubExt = "";

	public string TrackName = "";
	public string TrackNumber = "";
	public string Album = "";
	public string Artist = "";
	public string Genre = "";
	public string RecordedDate = "";
	public string Comment = "";

	//public int CropW = 0;
	//public int CropH = 0;
	public int CropL = 0;
	public int CropR = 0;
	public int CropT = 0;
	public int CropB = 0;
	public bool AutoCropError = false;

	public double StartPos = 0.0;
	public double EndPos = 0.0;
	public Gee.ArrayList<MediaClip> clip_list;
	
	//public int Status = 0;
	public FileStatus Status = FileStatus.PENDING;
	public bool IsValid;
	public string ProgressText = _("Queued");
	public int ProgressPercent = 0;

	public string InfoText = "";
	public string InfoTextFormatted = "";
	
	public bool HasAudio = false;
	public bool HasVideo = false;
	public bool HasSubs = false;
	public bool HasExtSubs = false;

	public string FileFormat = "";
	public string VideoFormat = "";
	public string AudioFormat = "";
	public int SourceWidth = 0;
	public int SourceHeight = 0;
	public double SourceFrameRate = 0;
	public int AudioChannels = 0;
	public int AudioSampleRate = 0;
	public int AudioBitRate = 0;
	public int VideoBitRate = 0;
	public int BitRate = 0;

	public string TempScriptFile;
	public string TempDirectory = "";
	public string LogFile = "";
	public string OutputFilePath = "";
	public long OutputFrameCount = 0;

	public static int ThumbnailWidth = 80; 
	public static int ThumbnailHeight= 64;
			
	public MediaFile(string filePath, string av_encoder){
		IsValid = false;
		if (file_exists (filePath) == false) { return; }

		clip_list = new Gee.ArrayList<MediaClip>();
		
		// set file properties ------------

		File f = File.new_for_path (filePath);
		File fp = f.get_parent();

		Path = filePath;
		Name = f.get_basename();
		Title = Name[0: Name.last_index_of(".",0)];
		Extension = Name[Name.last_index_of(".",0):Name.length];
		Location = fp.get_path();
		//stderr.printf(@"file=$filePath, name=$Name, title=$Title, ext=$Extension, dir=$Location\n");

		FileInfo fi = null;

		try{
			fi = f.query_info ("%s".printf(FileAttribute.STANDARD_SIZE), FileQueryInfoFlags.NONE, null);
			Size = fi.get_size();
		}
		catch (Error e) {
			log_error (e.message);
		}

		// get media information ----------

		query_mediainfo();
		if (Duration == 0) { return; }

		// search for subtitle files ---------------

		try{
	        var enumerator = fp.enumerate_children ("%s,%s".printf(FileAttribute.STANDARD_NAME,FileAttribute.STANDARD_TYPE), 0);
			var fileInfo = enumerator.next_file();
	        while (fileInfo != null) {
	            if (fileInfo.get_file_type() == FileType.REGULAR) {
		            string fname = fileInfo.get_name().down();
		            if (fname.has_prefix(Title.down()) && (fname.has_suffix (".srt")||fname.has_suffix (".sub")||fname.has_suffix (".ssa")||fname.has_suffix (".ttxt")||fname.has_suffix (".xml")||fname.has_suffix (".lrc")))
		            {
			            SubName = fileInfo.get_name();
			            SubFile = Location + "/" + SubName;
	                	SubExt = SubFile[SubFile.last_index_of(".",0):SubFile.length].down();
	                	HasExtSubs = true;
	                	//log ("file=%s, name=%s, ext=%s\n".printf(SubFile, SubName, SubExt));
	                }
	            }
	            fileInfo = enumerator.next_file();
	        }
        }
        catch(Error e){
	        log_error (e.message);
	    }


	    // get thumbnail ---------

	    generate_thumbnail(av_encoder);

		IsValid = true;
	}

	public void query_mediainfo(){
		InfoText = get_mediainfo (Path, true);

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
				else if (line.contains ("Text")){
					sectionType = "text";
					HasSubs = true;
				}
			}
			else{
				string[] arr = line.split (": ");
				if (arr.length != 2) { continue; }

				string key = arr[0].strip();
				string val = arr[1].strip();

				if (sectionType	== "general"){
					switch (key.down()) {
						case "duration/string":
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
						case "track":
							TrackName = val;
							break;
						case "track/position":
							TrackNumber = val;
							break;
						case "album":
							Album = val;
							break;
						case "performer":
							Artist = val;
							break;
						case "genre":
							Genre = val;
							break;
						case "recorded_date":
							RecordedDate = val;
							break;
						case "comment":
							Comment = val;
							break;
						case "format":
							FileFormat = val;
							break;
						case "overallbitrate/string":
							BitRate = int.parse(val.split(" ")[0].strip());
							break;
					}
				}
				else if (sectionType == "video"){
					switch (key.down()) {
						case "width/string":
							SourceWidth = int.parse(val.split(" ")[0].strip());
							break;
						case "height/string":
							SourceHeight = int.parse(val.split(" ")[0].strip());
							break;
						case "framerate/string":
						case "framerate_original/string":
							SourceFrameRate = double.parse(val.split(" ")[0].strip());
							break;
						case "format":
							VideoFormat = val;
							break;
						case "bitrate/string":
							VideoBitRate = int.parse(val.split(" ")[0].strip());
							break;
					}
				}
				else if (sectionType == "audio"){
					switch (key.down()) {
						case "channel(s)/string":
							AudioChannels = int.parse(val.split(" ")[0].strip());
							break;
						case "samplingrate/string":
							AudioSampleRate = (int)(double.parse(val.split(" ")[0].strip()) * 1000);
							break;
						case "format":
							AudioFormat = val;
							break;
						case "bitrate/string":
							AudioBitRate = int.parse(val.split(" ")[0].strip());
							break;
					}
				}
			}
		}
	}

	public void query_mediainfo_formatted(){
		InfoTextFormatted = get_mediainfo (Path, false);
	}

	public void prepare (string baseTempDir){
		TempDirectory = baseTempDir + "/" + timestamp2() + " - " + Name;
		LogFile = TempDirectory + "/" + "log.txt";
		TempScriptFile = TempDirectory + "/convert.sh";
		OutputFilePath = "";
		create_dir (TempDirectory);

		//initialize output frame count
		if (HasVideo && Duration > 0 && SourceFrameRate > 1) {
			OutputFrameCount = (long) ((Duration / 1000.0) * (SourceFrameRate));
		}
		else{
			OutputFrameCount = 0;
		}
	}

	public void generate_thumbnail(string av_encoder){
		if (HasVideo){
			ThumbnailImagePath = get_temp_file_path() + ".png";
			string std_out, std_err;
			execute_command_script_sync("%s -ss 1 -i \"%s\" -y -f image2 -vframes 1 -r 1 -s %dx%d \"%s\"".printf(av_encoder,Path,ThumbnailWidth,ThumbnailHeight,ThumbnailImagePath), out std_out, out std_err);
		}
		else{
			ThumbnailImagePath = "/usr/share/%s/images/%s".printf(AppShortName, "audio.svg");
		}
	}

	public bool crop_detect(){
		if (HasVideo == false) {
			AutoCropError = true;
			return false;
		}

		string params = get_file_crop_params (Path);
		string[] arr = params.split (":");

		int CropW = 0;
		int CropH = 0;
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

	public bool crop_enabled(){
		if ((CropL == 0) && (CropR == 0) && (CropT == 0) && (CropB == 0))
			return false;
		else
			return true;
	}

	public void crop_reset(){
		CropL = 0;
		CropT = 0;
		CropR = 0;
		CropB = 0;
	}

	public string crop_values_info(){
		if (crop_enabled())
			return "%i:%i:%i:%i".printf(CropL,CropT,CropR,CropB);
		else if (AutoCropError)
			return _("N/A");
		else
			return "";
	}

	public string crop_values_libav(){
		if (crop_enabled()){
			int w = SourceWidth - CropL - CropR;
			int h = SourceHeight - CropT - CropB;
			int x = CropL;
			int y = CropT;
			return "%i:%i:%i:%i".printf(w,h,x,y);
		}
		else{
			return "iw:ih:0:0";
		}
	}

	public string crop_values_x264(){
		if (crop_enabled())
			return "%i,%i,%i,%i".printf(CropL,CropT,CropR,CropB);
		else
			return "0,0,0,0";
	}

	public void play_source(string av_player){
		play_file(Path, av_player);
	}

	//TODO: Remove
	private void play_file(string file_path, string av_player){
		if (file_exists(file_path)){
			
			string output = "";
			string error = "";

			string cmd = "";
			switch(av_player){
				case "avplay":
				case "ffplay":
					cmd = "nohup %s -i \"%s\"".printf(av_player, file_path);
					break;
				default:
					cmd = "nohup %s \"%s\"".printf(av_player, file_path);
					break;
			}
		
			try {
				Process.spawn_command_line_sync(cmd, out output, out error);
			}
			catch(Error e){
				log_error (e.message);
			}
		}
	}
}

public class MediaClip : GLib.Object{
	public double StartPos = 0.0;
	public double EndPos = 0.0;

	public double Duration(){
		return (EndPos - StartPos);
	}
}

public class MediaStream : GLib.Object{
    public string Format = "";
    public int StreamIndex = -1;
    public int StreamTypeIndex = -1;
}

public class AudioStream : MediaStream{

}
