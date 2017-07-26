using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class MediaPlayer : GLib.Object{
	public MediaFile mFile;

	//playback state
	public string isRunning;
	public bool IsMuted = false;
    public bool IsPaused = false;
    public bool IsIdle = true;
	public double Position = 0.0;
	public int Volume = 70;
	
	//default state flags
    public bool MuteOnLoad = false;
    public bool PauseOnLoad = false;

	public uint WindowID = 0;
	//public string input_pipe = "";
	
    public string err_line;
	public string out_line;
	public string status_line;
	public string status_summary;
	public Gee.ArrayList<string> stdout_lines;
	public Gee.ArrayList<string> stderr_lines;
	public Pid proc_id;
	public DataInputStream dis_out;
	public DataInputStream dis_err;
	public DataOutputStream dos_inp;
	public int64 progress_count;
	public int64 progress_total;
	public bool is_running;
	
	public int CropL = 0;
	public int CropR = 0;
	public int CropT = 0;
	public int CropB = 0;

	private Regex rex_crop;
	private Regex rex_pause;
	private Regex rex_av;
	private Regex rex_audio;
	private Regex rex_video;
	private Regex rex_mpv;

	public MediaPlayer(){
        IsMuted = false;
        IsPaused = false;
        IsIdle = true;

        try{
			//[CROP] Crop area: X: 4..1275  Y: 40..689  (-vf crop=1264:640:8:46).
			//[CROP] Crop area: X: 1..1279  Y: 40..699  (-vf crop=1264:656:10:42).
			rex_crop = new Regex(""".*-vf crop=([0-9]+):([0-9]+):([0-9]+):([0-9]+)""");

			//  =====  PAUSE  =====
			rex_pause = new Regex(""".*=====  PAUSE  =====""");

			//A:   1.9 V:   1.9 A-V:  0.001 ct:  0.000   0/  0  1%  1%  0.4% 0 0
			rex_av = new Regex("""^A:[ \t]*([0-9.]+)[ \t]*V:[ \t]*([0-9.]+)[ \t]*""");

			//A:   1.9 V:   1.9 A-V:  0.001 ct:  0.000   0/  0  1%  1%  0.4% 0 0
			rex_video = new Regex("""^V:[ \t]*([0-9.]+)[ \t]*""");
			
			//A:   1.9 V:   1.9 A-V:  0.001 ct:  0.000   0/  0  1%  1%  0.4% 0 0
			rex_audio = new Regex("""^A:[ \t]*([0-9.]+)[ \t]*""");

			//1.793458 no no 50
			rex_mpv = new Regex("""([0-9.]*) (yes|no) (yes|no) ([0-9.])""");
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	public void StartPlayerWithCropFilter(){
		if (mFile != null){
			int x = mFile.CropL;
			int y = mFile.CropT;
			int w = mFile.SourceWidth - mFile.CropL - mFile.CropR;
			int h = mFile.SourceHeight - mFile.CropT - mFile.CropB;

			if (App.PrimaryPlayer == "mpv"){
				StartPlayer(" --vf=crop=%d:%d:%d:%d".printf(w,h,x,y));
			}
			else{
				StartPlayer(" -vf rectangle=%d:%d:%d:%d".printf(w,h,x,y));
			}
		}
		else{
			if (App.PrimaryPlayer == "mplayer"){
				StartPlayer("-vf rectangle"); //mplayer
			}
		}
	}

	public void StartPlayerWithCropDetect(){
		if (App.PrimaryPlayer == "mplayer"){
			StartPlayer("-vf cropdetect");
		}
		else{
			//StartPlayer("--vf=lavfi=cropdetect");
		}
	}

	public void Mpv_Add_CropDetectFilter(){
		if (App.PrimaryPlayer == "mpv"){
			write_to_stdin("vf add \"lavfi=cropdetect\"");
		}
	}

	
	public void Mpv_Remove_CropDetectFilter(){
		if (App.PrimaryPlayer == "mpv"){
			write_to_stdin("vf del \"lavfi=cropdetect\"");
		}
	}

	
	public void StartPlayer(string ExtraOptions = ""){
		
		string args = App.PrimaryPlayer;
		
		if (App.PrimaryPlayer == "mpv"){
			
			//options
			args += " --no-config --no-quiet --idle=yes --keep-open=yes --terminal --no-msg-color --input-file=/dev/stdin --no-fs --hwdec=no --sub-auto=fuzzy --vo=xv --ao=alsa --stop-screensaver --no-input-default-bindings --input-x11-keyboard=no --no-input-cursor --cursor-autohide=no --no-keepaspect --monitorpixelaspect=1 --osd-scale=1 --osd-level=0 --screenshot-format=jpg --ytdl=no";

			//status line format
			args += " --term-status-msg='${=time-pos} ${pause} ${mute} ${volume}'";
			
			//window id
			args += " --wid=%u".printf(WindowID);
		}
		else if (App.PrimaryPlayer == "mplayer"){

			//options
			args += " -slave -noquiet -msglevel all=6 -nofs -idle -osdlevel 0 -colorkey 0x101010";
			
			//widowid
			args += " -wid %u".printf(WindowID);
		}

		if (ExtraOptions.length > 0){
			args += " " + ExtraOptions.strip();
		}

        log_debug(args);

        run(args);

        sleep(500);
    }

    private bool run (string cmd) {
		string[] argv = new string[1];
		argv[0] = create_temp_bash_script(cmd);

		Pid child_pid;
		int input_fd;
		int output_fd;
		int error_fd;

		try {
			//execute script file
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

			is_running = true;

			proc_id = child_pid;

			//create stream readers
			var uis_out = new UnixInputStream(output_fd, false);
			var uis_err = new UnixInputStream(error_fd, false);
			var uos_inp = new UnixOutputStream(input_fd, false);
			dis_out = new DataInputStream(uis_out);
			dis_err = new DataInputStream(uis_err);
			dos_inp = new DataOutputStream(uos_inp);
			dis_out.newline_type = DataStreamNewlineType.ANY;
			dis_err.newline_type = DataStreamNewlineType.ANY;
			//dos_inp.newline_type = DataStreamNewlineType.ANY;

			try {
				//start thread for reading output stream
				Thread.create<void> (read_output_line, true);
			} catch (Error e) {
				log_error (e.message);
			}

			try {
				//start thread for reading error stream
				Thread.create<void> (read_error_line, true);
			} catch (Error e) {
				log_error (e.message);
			}

			return true;
		}
		catch (Error e) {
			log_error (e.message);
			return false;
		}
	}

	private void read_error_line() {
		try {
			MatchInfo match;

			err_line = dis_err.read_line (null);
			while (is_running && (err_line != null)) {
				if (rex_mpv.match(err_line, 0, out match)){
					Position = double.parse(match.fetch(1));
					IsPaused = (match.fetch(2) == "yes") ? true : false;
					IsMuted = (match.fetch(3) == "yes") ? true : false;
					Volume = int.parse(match.fetch(4));
				}
				else if (rex_av.match(err_line, 0, out match)){
					Position = double.parse(match.fetch(2));
					IsPaused = false;
					//log_debug("Pos=%.2f".printf(Position));
				}
				else if (rex_video.match(err_line, 0, out match)){
					Position = double.parse(match.fetch(1));
					IsPaused = false;
				}
				else if (rex_audio.match(err_line, 0, out match)){
					Position = double.parse(match.fetch(1));
					IsPaused = false;
				}
				else if (rex_pause.match(err_line, 0, out match)){
					IsPaused = true;
					//log_debug("PAUSED");
				}

				log_debug("err:" + err_line);
				err_line = dis_err.read_line (null); //read next
			}

			log_debug("stderr reader exited");
		}
		catch (Error e) {
			log_debug("In read_error_line()");
			log_error (e.message);
		}
	}

	private void read_output_line() {
		try {
			MatchInfo match;
			
			out_line = dis_out.read_line (null);
			while (is_running && (out_line != null)) {

				if (rex_crop.match (out_line, 0, out match)){
					int w = int.parse(match.fetch(1));
					int h = int.parse(match.fetch(2));
					int x = int.parse(match.fetch(3));
					int y = int.parse(match.fetch(4));

					//log_debug("match=%d,%d,%d,%d".printf(w,h,x,y));
					
					int cropL = x;
					int cropR = mFile.SourceWidth - w - x;
					int cropT = y;
					int cropB = mFile.SourceHeight - h - y;
					
					if (cropL < mFile.CropL){
						mFile.CropL = cropL;
					}
					if (cropR < mFile.CropR){
						mFile.CropR = cropR;
					}
					if (cropT < mFile.CropT){
						mFile.CropT = cropT;
					}
					if (cropB < mFile.CropB){
						mFile.CropB = cropB;
					}
				}

				log_debug("out:" + out_line);
				out_line = dis_out.read_line (null);  //read next
			}

			//is_running = false;

			//input_pipe = "";
			log_debug("stdout reader exited");
		}
		catch (Error e) {
			log_debug("In read_output_line()");
			log_error (e.message);
		}
	}

	private void write_to_stdin(string line) {
		try {
			if (is_running){
				log_debug(line);
				dos_inp.put_string(line + "\n");
				dos_inp.flush();
			}
		}
		catch (Error e) {
			log_debug("In write_to_stdin()");
			log_error (e.message);
		}
	}

	public void Open(MediaFile _mFile, bool pause, bool mute, bool loop){
		mFile = _mFile;

		string f = mFile.Path;
		//escape: \ \n "
        f = f.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
        f = "\"" + f + "\"";
        
		if (App.PrimaryPlayer == "mpv"){
			write_to_stdin("loadfile %s".printf(f));
		}
		else{
			write_to_stdin("loadfile %s".printf(f));
		}
		
		if (pause){
			FrameStep(); //'frame_step' will pause the video, 'pause' will toggle
		}
		if (mute){
			Mute();
		}
		if (loop){
			Loop();
		}
	}

	public void Loop(){
		if (App.PrimaryPlayer == "mpv"){
			write_to_stdin("cycle loop 100 ");
		}
		else{
			write_to_stdin("loop 100 ");
		}
	}

	public void Pause(){
		FrameStep();
	}

	public void UnPause(){
		if (IsPaused){
			PauseToggle();
		}
	}
	
	public void PauseToggle(){
		//pause/unpause
		if (App.PrimaryPlayer == "mpv"){
			write_to_stdin("cycle pause ");
		}
		else{
			write_to_stdin("pause ");
		}
	}

	public void Mute(){

		log_debug("Mute()");
		
		if (App.PrimaryPlayer == "mplayer"){
			write_to_stdin("mute 1");
		}
		else{
			write_to_stdin("cycle mute 1");
		}

		IsMuted = true;
	}

	public void UnMute(){

		log_debug("UnMute()");
		
		if (App.PrimaryPlayer == "mplayer"){
			write_to_stdin("mute 0");
		}
		else{
			write_to_stdin("cycle mute 0");
		}

		IsMuted = false;
	}

	public void SetVolume(int percent){
		Volume = percent;
		if (App.PrimaryPlayer == "mpv"){
			write_to_stdin("set volume %d".printf(Volume));
		}
		else{
			write_to_stdin("volume %d 1".printf(Volume));
		}
	}
	
	public void Stop(){
		write_to_stdin("stop ");
	}

	public void ChangeRectangle(int parameter, int amount){
		write_to_stdin("change_rectangle %d %d ".printf(parameter, amount));
	}

	public void UpdateRectangle_Left(int change){
		ChangeRectangle(2, change);
		ChangeRectangle(0, -change);
		if (IsPaused){
			FrameStep();
		}
	}

	public void UpdateRectangle_Right(int change){
		//ChangeRectangle(2, change);
		ChangeRectangle(0, -change);
		if (IsPaused){
			FrameStep();
		}
	}

	public void UpdateRectangle_Top(int change){
		ChangeRectangle(3, change);
		ChangeRectangle(1, -change);
		if (IsPaused){
			FrameStep();
		}
	}

	public void UpdateRectangle_Bottom(int change){
		//ChangeRectangle(3, change);
		ChangeRectangle(1, -change);
		if (IsPaused){
			FrameStep();
		}
	}

	public void Mpv_Crop(){
		int w = mFile.SourceWidth - mFile.CropL - mFile.CropR;
		int h = mFile.SourceHeight - mFile.CropT - mFile.CropB;
		int x = mFile.CropL;
		int y = mFile.CropT;
		
		write_to_stdin("vf set \"crop=%d:%d:%d:%d\"".printf(w,h,x,y));
	}
	
	public void FrameStep(){
		write_to_stdin("frame_step ");
	}

	public void SetRectangle(){
		ChangeRectangle(0, - mFile.CropL - mFile.CropR); //0=width
		FrameStep();
		ChangeRectangle(1, - mFile.CropT - mFile.CropB); //1=height
		FrameStep();
		ChangeRectangle(2, mFile.CropL); //2=x
		FrameStep();
		ChangeRectangle(3, mFile.CropT); //3=y
		FrameStep();
	}
	
	public void Seek(double seconds){
		if (App.PrimaryPlayer == "mpv"){
			write_to_stdin("seek %.1f absolute".printf(seconds));
		}
		else{
			write_to_stdin("seek %.1f 2".printf(seconds));
		}
	}

	public void Exit(){
		write_to_stdin("quit ");
		is_running = false;
		//process_kill(proc_id);
	}
}

