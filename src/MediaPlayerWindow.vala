/*
 * CropVideoSingleWindow.vala
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

using Gtk;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class MediaPlayerWindow : Gtk.Window {
	private Gtk.Box vboxMain;

	//crop
	private Gtk.SpinButton spinCropL;
	private Gtk.SpinButton spinCropR;
	private Gtk.SpinButton spinCropT;
	private Gtk.SpinButton spinCropB;
	private Gtk.Label lblSourceSize;
	private Gtk.Label lblCroppedSize;
	
	//trim
	private Gtk.Grid grid_trim_basic;
	private Gtk.Grid grid_trim_advanced;
	private Gtk.SpinButton spinStartPos;
	private Gtk.SpinButton spinEndPos;

	//player
	private Gtk.DrawingArea canvas;
	private Gtk.DrawingArea timeline;
	private Gtk.Scale scalePos;
	private Gtk.Scale scaleVolume;
	private Gtk.Button btnPlay;
	private Gtk.Button btnMute;
	private Gtk.Button btnFullscreen;
	private Gtk.ComboBox cmbZoom;
	private MediaPlayer player;
	private MediaFile mFile;
	private MediaClip mClipSelected;
	private MediaClip mClipNew;
	private uint tmr_status = 0;
	private bool IsMaximized = false;
	
	//window
	private uint tmr_init = 0;
	private string action = "";
	private bool crop_detect_is_running = false;
	
	public static Gtk.Window CropVideo(MediaFile mf, Gtk.Window parent){
		var win = new MediaPlayerWindow(mf, parent, "crop");
		parent.hide();
		return win;
	}

	public static Gtk.Window TrimFile(MediaFile mf, Gtk.Window parent){
		var win = new MediaPlayerWindow(mf, parent, "trim");
		parent.hide();
		return win;
	}

	public static Gtk.Window PlayFile(MediaFile mf){
		var win = new MediaPlayerWindow(mf, null, "play");
		return win;
	}

	public void set_window_parent(Gtk.Window? parent){
		if (parent != null){
			set_transient_for(parent);
			set_destroy_with_parent(true);
			set_modal(true);
			//use destroy event (delete_event will not be trigerred for Finish button)
			this.destroy.connect(()=>{
				parent.present();
				//return false;
			});
		}
		else{
			set_modal(false);
		}
	}
	
	public MediaPlayerWindow(MediaFile _mFile, Gtk.Window? parent, string _action) {
        set_window_parent(parent);
		//window_position = WindowPosition.CENTER_ALWAYS;
		icon = get_app_icon(16);
		
		deletable = true;
		resizable = false;

		action = _action;
		
		player = new MediaPlayer();
		player.mFile = _mFile;
		mFile = _mFile;

		if (action == "crop"){
			title = "Crop Video";
		}
		else if (action == "trim"){
			title = "Trim";
		}
		else if (action == "play"){
			title = mFile.Name + " - Selene";
		}

		//vboxMain
		vboxMain = new Gtk.Box(Orientation.VERTICAL,0);
		add(vboxMain);

		if (action == "crop"){
			init_ui_file_crop_options();
		}
		else if (action == "trim"){
			init_ui_file_trim_options();
			init_ui_file_trim_options_advanced();
		}

		init_ui_player();

		init_ui_player_controls();

		//use destroy event (delete_event will not be trigerred for Finish button)
		this.destroy.connect(()=>{
			status_timer_stop();
			player.Exit();
			//return false;
		});
		
		show_all();
		
		tmr_init = Timeout.add(100, init_delayed);
	}
	
	private bool init_delayed() {
		/* any actions that need to run after window has been displayed */
		
		if (tmr_init > 0) {
			Source.remove(tmr_init);
			tmr_init = 0;
		}

		if (mFile.clip_list.size > 0){
			grid_trim_basic.visible = false;

			grid_trim_advanced.no_show_all = false;
			grid_trim_advanced.show_all();
			grid_trim_advanced.visible = true;
		}
		else{
			grid_trim_advanced.visible = false;

			grid_trim_basic.no_show_all = false;
			grid_trim_basic.show_all();
			grid_trim_basic.visible = true;
		}

		load_file();

		return false;
	}
	
	private void init_ui_file_crop_options(){
		var grid = new Gtk.Grid();
		grid.margin = 6;
		grid.row_spacing = 3;
		grid.column_spacing = 3;
		vboxMain.add(grid);
		
		Gtk.Adjustment adj;
		Gtk.SpinButton spin;
		Gtk.Label label;

		string tt = _("Scroll mouse wheel to adjust");
		
		//left -----------------------------------------------
		
		label = new Gtk.Label(_("Left:"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,0,1,1);

		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text(tt);
		grid.attach(spin,1,0,1,1);
		spinCropL = spin;

		//right -----------------------------------------------
		
		label = new Gtk.Label(_("Right:"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,1,1,1);
		
		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text(tt);
		grid.attach(spin,1,1,1,1);
		spinCropR = spin;

		//top -----------------------------------------------
		
		label = new Gtk.Label(_("Top:"));
		label.xalign = (float) 1.0;
		grid.attach(label,2,0,1,1);

		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text(tt);
		grid.attach(spin,3,0,1,1);
		spinCropT = spin;
		
		//bottom -----------------------------------------------
		
		label = new Gtk.Label(_("Bottom:"));
		label.xalign = (float) 1.0;
		grid.attach(label,2,1,1,1);

		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 0.5;
		spin.set_tooltip_text(tt);
		grid.attach(spin,3,1,1,1);
		spinCropB = spin;

		//source -----------------------------------------------
		
		label = new Gtk.Label(_("Source:"));
		label.xalign = (float) 1.0;
		label.margin_left = 18;
		grid.attach(label,4,0,1,1);

		//cropped -----------------------------------------------
		
		label = new Gtk.Label(_("Cropped:"));
		label.xalign = (float) 1.0;
		label.margin_left = 18;
		grid.attach(label,4,1,1,1);
		
		lblSourceSize = new Gtk.Label("0x0");
		lblSourceSize.xalign = (float) 1.0;
		grid.attach(lblSourceSize,5,0,1,1);

		lblCroppedSize = new Gtk.Label("0x0");
		lblCroppedSize.xalign = (float) 1.0;
		grid.attach(lblCroppedSize,5,1,1,1);

		//detect -----------------------------------------------'
		
		var button = new Button.with_label(_("Detect Borders"));
		button.margin_left = 18;
		button.set_tooltip_text(_("Detect black borders in the video and set cropping parameters"));
        grid.attach(button,6,0,1,1);

		button.clicked.connect(btnDetect_clicked);

		//finish -----------------------------------------------
		
		button = new Button.with_label(_("Finish"));
		button.margin_left = 18;
        grid.attach(button,6,1,1,1);

        button.clicked.connect(()=>{ this.destroy(); });
	}

	private void init_ui_file_trim_options(){
		var grid = new Gtk.Grid();
		grid.margin = 6;
		grid.row_spacing = 3;
		grid.column_spacing = 3;
		grid.no_show_all = true;
		vboxMain.add(grid);
		grid_trim_basic = grid;
		
		Gtk.Adjustment adj;
		Gtk.SpinButton spin;
		Gtk.Label label;
		Gtk.Button button;
		
		//start -----------------------------------------
		
		label = new Gtk.Label(_("Start (sec):"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,0,1,1);
		 
		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 1.0;
		spin.digits = 3;
		grid.attach(spin,1,0,1,1);
		
		spinStartPos = spin;
	
		//end ----------------
		
		label = new Gtk.Label(_("End (sec):"));
		label.xalign = (float) 1.0;
		grid.attach(label,0,1,1,1);
		
		adj = new Gtk.Adjustment(0, 0, 99999, 1, 1, 0);
		spin = new Gtk.SpinButton (adj, 1, 0);
		spin.xalign = (float) 1.0;
		spin.digits = 3;
		grid.attach(spin,1,1,1,1);

		spinEndPos = spin;

		//set start ---------------------------
		
		button = new Button.with_label(_("Set"));
		button.set_tooltip_text(_("Set current playback position as starting position"));
        grid.attach(button,2,0,1,1);

		button.clicked.connect(()=>{
			spinStartPos.adjustment.value = player.Position;
		});

		//set end ----------------------
		
		button = new Button.with_label(_("Set"));
		button.set_tooltip_text(_("Set current playback position as ending position"));
        grid.attach(button,2,1,1,1);

        button.clicked.connect(()=>{
			spinEndPos.adjustment.value = player.Position;
		});
        
		//advanced -------------------------------
		
		button = new Button.with_label(_("Advanced Mode"));
		button.margin_left = 24;
		button.set_tooltip_text(_("Select multiple segments"));
        grid.attach(button,3,0,1,1);

		button.clicked.connect(()=>{
			grid_trim_basic.visible = false;

			grid_trim_advanced.no_show_all = false;
			grid_trim_advanced.show_all();
			grid_trim_advanced.visible = true;
		});

		//finish ---------------------------------------------
		
		button = new Button.with_label(_("Finish"));
		button.margin_left = 24;
        grid.attach(button,3,1,1,1);

        button.clicked.connect(()=>{ this.destroy(); });
	}

	private void init_ui_file_trim_options_advanced(){
		var grid = new Gtk.Grid();
		grid.margin = 6;
		grid.row_spacing = 3;
		grid.column_spacing = 3;
		grid.column_homogeneous = true;
		grid.no_show_all = true;
		vboxMain.add(grid);
		grid_trim_advanced = grid;
		
		Gtk.Adjustment adj;
		Gtk.SpinButton spin;
		Gtk.Label label;
		Gtk.Button button;

		//select the segments to be included in output file
		label = new Gtk.Label(_("Select the segments to include in output file:"));
		label.xalign = (float) 0.0;
		grid.attach(label,0,0,5,1);

		//timeline -----------------------------------
		
		timeline = new Gtk.DrawingArea();
		timeline.set_size_request(-1, 30);
		timeline.hexpand = true;
		
		timeline.draw.connect(timeline_draw);
		
		timeline.add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		timeline.button_press_event.connect(timeline_button_press);

		timeline.add_events(Gdk.EventMask.POINTER_MOTION_MASK);
		timeline.motion_notify_event.connect(timeline_motion_notify_event);

		var scroll = new Gtk.ScrolledWindow(null, null);
		scroll.set_shadow_type (ShadowType.ETCHED_IN);
		scroll.hscrollbar_policy = PolicyType.NEVER;
		scroll.vscrollbar_policy = PolicyType.NEVER;
		scroll.expand = true;
		scroll.margin_bottom = 6;
		scroll.add (timeline);
		grid.attach(scroll,0,1,5,1);

		//start segment -------------------------------------
		
		button = new Button.with_label(_("Start Segment"));
        grid.attach(button,0,2,1,1);
		
        button.clicked.connect(()=>{
			mClipNew = new MediaClip();
			if (mClipNew != null){
				mClipNew.StartPos = player.Position;
				timeline_redraw();
			}
		});
		
		//end segment -------------------------------------
		
		button = new Button.with_label(_("End Segment"));
        grid.attach(button,1,2,1,1);

		button.clicked.connect(()=>{
			if (mClipNew != null){
				mClipNew.EndPos = player.Position;
				mFile.clip_list.add(mClipNew);
				timeline_redraw();
				//log_msg("added:%.1f,%.1f".printf(mClip.StartPos,mClip.EndPos));
			}
		});

		//delete segment -------------------------------------
			
        button = new Button.with_label(_("Delete Segment"));
        grid.attach(button,2,2,1,1);

		button.clicked.connect(()=>{
			if (mClipSelected != null){
				for(int i = 0; i < mFile.clip_list.size; i++){
					var clip = mFile.clip_list[i];
					if ((clip.StartPos == mClipSelected.StartPos) && (clip.EndPos == mClipSelected.EndPos)){
						mFile.clip_list.remove(clip);
						break;
					}
				}
				timeline_redraw();
			}
		});

		//basic mode ---------------------------------------
		
		button = new Button.with_label(_("Basic Mode"));
        grid.attach(button,3,2,1,1);
        
        button.clicked.connect(()=>{
			grid_trim_basic.no_show_all = false;
			grid_trim_basic.show_all();
			grid_trim_basic.visible = true;
			
			grid_trim_advanced.visible = false;
		});

		//finish ---------------------------------------------
		
		button = new Button.with_label(_("Finish"));
        grid.attach(button,4,2,1,1);

        button.clicked.connect(()=>{ this.destroy(); });
	}

	private bool timeline_draw(Cairo.Context context){
		weak Gtk.StyleContext style_context = timeline.get_style_context ();
		var color_default = style_context.get_color (0);

		var color_blue_100 = Gdk.RGBA();
		color_blue_100.parse("#BBDEFB");
		color_blue_100.alpha = 1.0;

		var color_blue_200 = Gdk.RGBA();
		color_blue_200.parse("#90CAF9");
		color_blue_200.alpha = 1.0;

		var color_blue_300 = Gdk.RGBA();
		color_blue_300.parse("#64B5F6");
		color_blue_300.alpha = 1.0;

		var color_white = Gdk.RGBA();
		color_white.parse("white");
		color_white.alpha = 1.0;

		var color_black = Gdk.RGBA();
		color_black.parse("black");
		color_black.alpha = 1.0;

		var color_grey_700 = Gdk.RGBA();
		color_grey_700.parse("#616161");
		color_grey_700.alpha = 1.0;

		var color_grey_800 = Gdk.RGBA();
		color_grey_800.parse("#424242");
		color_grey_800.alpha = 1.0;

		var color_red = Gdk.RGBA();
		color_red.parse("red");
		color_red.alpha = 1.0;

		var color_blue = Gdk.RGBA();
		color_blue.parse("blue");
		color_blue.alpha = 1.0;

		color_default = color_black;

		int canvas_w = timeline.get_allocated_width();
		int canvas_h = timeline.get_allocated_height();

		int w = 0;
		int h = 0;
		int x = 0;
		int y = 0;

		//------ BEGIN CONTEXT -------------------------------------------------
		//Draw white background
		
		context.set_line_width (1);
		Gdk.cairo_set_source_rgba (context, color_white);
		context.rectangle(0, 0, canvas_w, canvas_h);

		context.fill();
		//------ END CONTEXT ---------------------------------------------------

		//------ BEGIN CONTEXT -------------------------------------------------
		//Draw border
		
		context.set_line_width (1);
		Gdk.cairo_set_source_rgba (context, color_black);
		
		context.move_to(0,0);
		context.line_to(canvas_w,0);
		context.line_to(canvas_w,canvas_h);
		context.line_to(0,canvas_h);
		context.line_to(0,0);
		
		context.stroke();
		//------ END CONTEXT ---------------------------------------------------
		
		//------ BEGIN CONTEXT -------------------------------------------------
		//Draw segments
		
		context.set_line_width (1);
		Gdk.cairo_set_source_rgba (context, color_grey_700);
		
		foreach(MediaClip clip in mFile.clip_list){
			if (clip == mClipSelected){
				Gdk.cairo_set_source_rgba (context, color_grey_800);
			}
			else{
				Gdk.cairo_set_source_rgba (context, color_grey_700);
			}
			
			x = (int)((clip.StartPos / (mFile.Duration/1000.0)) * canvas_w);
			y = 0;
			w = (int)((clip.Duration() / (mFile.Duration/1000.0)) * canvas_w);
			h = canvas_h;
			
			context.rectangle(x, y, w, h);
			context.fill();

			//log_msg("clip: %.1f x %d = %d".printf((clip.StartPos / (mFile.Duration/1000.0)),canvas_w,x));
		}
		
		//------ END CONTEXT ---------------------------------------------------

		//------ BEGIN CONTEXT -------------------------------------------------
		//Draw start point of new segment
		
		context.set_line_width (1);
		Gdk.cairo_set_source_rgba (context, color_black);

		if ((mClipNew != null) && (mClipNew.EndPos < 0.1)){
			x = (int)((mClipNew.StartPos / (mFile.Duration/1000.0)) * canvas_w);

			context.move_to(x, 0);
			context.line_to(x, canvas_h);
		
			context.stroke();
		}
		//------ END CONTEXT ---------------------------------------------------

		//------ BEGIN CONTEXT -------------------------------------------------
		//Draw play position
		
		context.set_line_width (1);
		Gdk.cairo_set_source_rgba (context, color_red);

		if ((player.Position > 0) && (player.Position < (mFile.Duration/1000.0))){
			x = (int)((player.Position / (mFile.Duration/1000.0)) * canvas_w);

			context.move_to(x, 0);
			context.line_to(x, canvas_h);
		
			context.stroke();
		}
		
		//------ END CONTEXT ---------------------------------------------------
		
		return true;
	}

	private void timeline_redraw(){
		timeline.queue_draw_area(0, 0,timeline.get_allocated_width(),timeline.get_allocated_height());
	}

	private bool timeline_motion_notify_event(Gdk.EventMotion event){
		//get position
		int w = timeline.get_allocated_width();
		double pos = ((event.x * 1.0) / w) * (mFile.Duration/1000.0);

		//get clip
		int index = 0;
		MediaClip current_clip = null;
		foreach(MediaClip clip in mFile.clip_list){
			index++;
			if ((clip.StartPos < pos) && (clip.EndPos > pos)){
				current_clip = clip;
				break;
			}
		}

		string msg = "";
		string time = "";
			
		if (current_clip != null){
			msg += "<b>Clip #%d</b>\n\n".printf(index);
			time = format_duration((long) (current_clip.StartPos * 1000.0), true);
			msg += "Start Pos:\t%s = %.3f sec\n".printf(time,current_clip.StartPos);
			time = format_duration((long) (current_clip.EndPos * 1000.0), true);
			msg += "End Pos:\t%s = %.3f sec\n".printf(time,current_clip.EndPos);
			time = format_duration((long) (current_clip.Duration() * 1000.0), true);
			msg += "Duration:\t%s = %.3f sec".printf(time,current_clip.Duration());
			timeline.set_tooltip_markup(msg);
		}
		else{
			//time = format_duration((long) (pos * 1000.0));
			//msg += "<b>Position:</b> %s (%0.03f)".printf(time, pos);
			//timeline.set_tooltip_markup(msg);
		}

		return true;
	}

	private bool timeline_button_press(Gdk.EventButton event){
		//get position
		int w = timeline.get_allocated_width();
		double pos = ((event.x * 1.0) / w) * (mFile.Duration/1000.0);

		//get clip
		int index = 0;
		MediaClip current_clip = null;
		foreach(MediaClip clip in mFile.clip_list){
			index++;
			if ((clip.StartPos < pos) && (clip.EndPos > pos)){
				current_clip = clip;
				break;
			}
		}
		mClipSelected = current_clip;

		//seek
		player.Seek(pos);
		
		timeline_redraw();
		
		return true;
	}
	//crop

	private void spinCrop_value_changed_connect(){
		spinCropL.value_changed.connect(spinCropL_value_changed);
		spinCropR.value_changed.connect(spinCropR_value_changed);
		spinCropT.value_changed.connect(spinCropT_value_changed);
		spinCropB.value_changed.connect(spinCropB_value_changed);
	}
	
	private void spinCrop_value_changed_disconnect(){
		spinCropL.value_changed.disconnect(spinCropL_value_changed);
		spinCropR.value_changed.disconnect(spinCropR_value_changed);
		spinCropT.value_changed.disconnect(spinCropT_value_changed);
		spinCropB.value_changed.disconnect(spinCropB_value_changed);
	}
	
	private void spinCropL_value_changed(){
		int original = mFile.CropL;
		int modified = (int) spinCropL.get_value();
		int change = modified - original;
		mFile.CropL = modified;

		if (App.PrimaryPlayer == "mplayer"){
			player.UpdateRectangle_Left(change);
		}
		else{
			player.Mpv_Crop();
			CropCanvas(true);
		}
		
		update_label_for_cropped_size();
	}

	private void spinCropR_value_changed(){
		int original = mFile.CropR;
		int modified = (int) spinCropR.get_value();
		int change = modified - original;
		mFile.CropR = modified;

		if (App.PrimaryPlayer == "mplayer"){
			player.UpdateRectangle_Right(change);
		}
		else{
			player.Mpv_Crop();
			CropCanvas(true);
		}
		
		update_label_for_cropped_size();
	}

	private void spinCropT_value_changed(){
		int original = mFile.CropT;
		int modified = (int) spinCropT.get_value();
		int change = modified - original;
		mFile.CropT = modified;

		if (App.PrimaryPlayer == "mplayer"){
			player.UpdateRectangle_Top(change);
		}
		else{
			player.Mpv_Crop();
			CropCanvas(true);
		}
		
		update_label_for_cropped_size();
	}

	private void spinCropB_value_changed(){
		int original = mFile.CropB;
		int modified = (int) spinCropB.get_value();
		int change = modified - original;
		mFile.CropB = modified;

		if (App.PrimaryPlayer == "mplayer"){
			player.UpdateRectangle_Bottom(change);
		}
		else{
			player.Mpv_Crop();
			CropCanvas(true);
		}
		
		update_label_for_cropped_size();
	}

	private void btnDetect_clicked(){

		var status_msg = _("Detecting borders...");
		var dlg = new SimpleProgressWindow.with_parent(this, status_msg);
		dlg.set_title(_("Please Wait..."));
		dlg.show_all();
		gtk_do_events();
	
		if (App.PrimaryPlayer == "mplayer"){

			//get total count
			App.progress_total = 10;
			App.progress_count = 0;

			//init values
			mFile.CropL = 9999;
			mFile.CropR = 9999;
			mFile.CropT = 9999;
			mFile.CropB = 9999;
		
			//restart mplayer with crop detect filter
			player.Exit();
			player.StartPlayerWithCropDetect();
			player.Open(mFile, false, true, true);

			//seek
			double duration = (mFile.Duration / 1000.0);
			double step = duration / 10.0;
			for(int i = 0; i < 10; i++){
				player.Seek(step * i);
				sleep(100);
				App.progress_count++;
				dlg.update_progressbar();
			}

			//restart mplayer with crop filter
			player.Exit();
			player.StartPlayerWithCropFilter();
			load_file();
		}
		else{
		
			try {
				crop_detect_is_running = true;
				Thread.create<void> (ffmpeg_crop_detect_thread, true);
			} catch (ThreadError e) {
				crop_detect_is_running = false;
				log_error (e.message);
			}

			dlg.pulse_start();
			while (crop_detect_is_running) {
				dlg.update_message(status_msg);
				dlg.sleep(200);
			}
		}

		if ((mFile.CropL == 9999)||(mFile.CropL < 0)){
			mFile.CropL = 0;
		}
		if ((mFile.CropR == 9999)||(mFile.CropR < 0)){
			mFile.CropR = 0;
		}
		if ((mFile.CropT == 9999)||(mFile.CropT < 0)){
			mFile.CropT = 0;
		}
		if ((mFile.CropB == 9999)||(mFile.CropB < 0)){
			mFile.CropB = 0;
		}
			
		dlg.finish(_("Detected Parameters: %d, %d, %d, %d").printf(mFile.CropL,mFile.CropR,mFile.CropT,mFile.CropB));

		update_spinbutton_values();

		if (App.PrimaryPlayer == "mpv"){
			player.Mpv_Crop();
			CropCanvas(true);
		}
	}

	private void ffmpeg_crop_detect_thread() {
		mFile.crop_detect();
		crop_detect_is_running = false;
	}
	
	private void update_label_for_cropped_size(){
		lblCroppedSize.label = "%dx%d".printf((mFile.SourceWidth - mFile.CropL - mFile.CropR),(mFile.SourceHeight - mFile.CropT - mFile.CropB));
	}

	//trim
	
	private void spinTrim_value_changed_connect(){
		spinStartPos.value_changed.connect(spinStartPos_value_changed);
		spinEndPos.value_changed.connect(spinEndPos_value_changed);
	}
	
	private void spinTrim_value_changed_disconnect(){
		spinStartPos.value_changed.disconnect(spinStartPos_value_changed);
		spinEndPos.value_changed.disconnect(spinEndPos_value_changed);
	}
	
	private void spinStartPos_value_changed(){
		mFile.StartPos = spinStartPos.adjustment.value;
	}

	private void spinEndPos_value_changed(){
		mFile.EndPos = spinEndPos.adjustment.value;
	}

	//load file
	
	private void load_file(){
		canvas.set_size_request(mFile.SourceWidth, mFile.SourceHeight);
		
		if (action == "crop"){
			load_file_for_crop();
		}
		else if (action == "trim"){
			load_file_for_trim();
		}
		else if (action == "play"){
			load_file_for_play();
		}

		btnMute.visible = mFile.HasAudio;
		btnFullscreen.visible = mFile.HasVideo;
		cmbZoom.visible = mFile.HasVideo;
		
		scalePos.adjustment.upper = (mFile.Duration/1000.0);
		
		status_timer_start();
	}
	
	private void load_file_for_crop(){
		cmbZoom_changed();
		
		player.Open(mFile, true, false, true);
		
		update_spinbutton_values();

		if (!player.IsPaused){
			player.PauseToggle();
		}
	}

	private void update_spinbutton_values(){
        spinCrop_value_changed_disconnect();
        
		spinCropL.adjustment.value = mFile.CropL;
		spinCropR.adjustment.value = mFile.CropR;
		spinCropT.adjustment.value = mFile.CropT;
		spinCropB.adjustment.value = mFile.CropB;
		
		lblSourceSize.label = "%dx%d".printf(mFile.SourceWidth,mFile.SourceHeight);
		update_label_for_cropped_size();
		
		spinCrop_value_changed_connect();
	}

	private void load_file_for_trim(){
		cmbZoom_changed();

		spinTrim_value_changed_disconnect();
		
		spinStartPos.adjustment.value = mFile.StartPos;
		spinEndPos.adjustment.value = mFile.EndPos;

		spinTrim_value_changed_connect();
		
		player.Open(mFile, false, false, true);
	}

	private void load_file_for_play(){
		cmbZoom_changed();

		player.Open(mFile, false, false, true);
	}

	//player
	
	private void init_ui_player(){
		canvas = new Gtk.DrawingArea();
		canvas.set_size_request(400,300);
		canvas.expand = true;
		canvas.halign = Align.CENTER;
		vboxMain.pack_start (canvas, false, false, 0);

        this.canvas.realize.connect(() => {
			player.WindowID = get_widget_xid(canvas);
			if (action == "crop"){
				player.StartPlayerWithCropFilter();
			}
			else if (action == "trim"){
				player.StartPlayer();
			}
			else if (action == "play"){
				player.StartPlayer();
			}
		});
	}
	
	private void init_ui_player_controls(){
		var hboxControls = new Gtk.Box(Orientation.HORIZONTAL, 6);
		hboxControls.margin = 6;
		vboxMain.add(hboxControls);

		//btnPlay
		btnPlay = new Gtk.Button();
		btnPlay.always_show_image = true;
		hboxControls.add(btnPlay);

		btnPlay.clicked.connect(() => {
			player.PauseToggle();
			set_play_icon();
		});

		//btnMute
		btnMute = new Gtk.Button();
		btnMute.always_show_image = true;
		hboxControls.add(btnMute);

		btnMute.clicked.connect(() => {
			if (player.IsMuted){
				player.UnMute();
			}
			else{
				player.Mute();
			}
			set_mute_icon();
		});

		//btnFullscreen
		btnFullscreen = new Gtk.Button();
		btnFullscreen.always_show_image = true;
		hboxControls.add(btnFullscreen);

		btnFullscreen.clicked.connect(() => {
			IsMaximized = !IsMaximized;
			if (IsMaximized){
				this.fullscreen();
				vboxMain.set_child_packing(canvas, true, true, 0, Gtk.PackType.START);
				canvas.halign = Align.FILL;
				canvas.valign = Align.FILL;
			}
			else{
				this.unfullscreen();
				cmbZoom_changed();
			}
			set_fullscreen_icon();
		});


		//scalePos
		scalePos = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1000, 1);
		scalePos.adjustment.value = 0;
		//scalePos.has_origin = true;
		scalePos.value_pos = PositionType.BOTTOM;
		scalePos.hexpand = true;
		scalePos.set_size_request(300,-1);
		hboxControls.add(scalePos);

		scalePos_value_changed_connect();
		
		scalePos.format_value.connect((val)=>{
			return format_duration((long) (val * 1000.0), true) + " / " + format_duration(mFile.Duration, true);
		});

		//scaleVolume
		scaleVolume = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);
		scaleVolume.adjustment.value = 70;
		scaleVolume.has_origin = true;
		scaleVolume.value_pos = PositionType.BOTTOM;
		scaleVolume.hexpand = false;
		scaleVolume.set_size_request(100,-1);
		hboxControls.add(scaleVolume);

		scaleVolume.value_changed.connect(()=>{
			player.SetVolume((int)scaleVolume.adjustment.value);
		});

		//cmbZoom
		cmbZoom = new ComboBox();
		var textCell = new CellRendererText();
        cmbZoom.pack_start(textCell, false);
        cmbZoom.set_attributes(textCell, "text", 0);
        hboxControls.add(cmbZoom);

        //populate
        TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("25%"),1,"0.25");
		model.append (out iter);
		model.set (iter,0,_("50%"),1,"0.50");
		model.append (out iter);
		model.set (iter,0,_("75%"),1,"0.75");
		model.append (out iter);
		model.set (iter,0,_("100%"),1,"1.0");
		model.append (out iter);
		model.set (iter,0,_("200%"),1,"2.0");
		cmbZoom.set_model(model);

		if (mFile.SourceWidth > (Gdk.Screen.get_default().get_width() / 2)){
			cmbZoom.active = 2;
		}
		else{
			cmbZoom.active = 3;
		}
		
		cmbZoom.changed.connect(cmbZoom_changed);

		set_play_icon();
		set_mute_icon();
		set_fullscreen_icon();
	}

	private void cmbZoom_changed(){
		if (App.PrimaryPlayer == "mpv"){
			CropCanvas(true);
		}
		else{
			CropCanvas(false);
		}
	}

	private void CropCanvas(bool cropCanvas){
		double zoom = double.parse(gtk_combobox_get_value(cmbZoom,1,"1.0"));
		int zoomWidth, zoomHeight;
		
		if (cropCanvas){
			zoomWidth = (int) ((mFile.SourceWidth - mFile.CropL - mFile.CropR) * zoom * 1.0);
			zoomHeight = (int) ((mFile.SourceHeight - mFile.CropT - mFile.CropB) * zoom * 1.0);
		}
		else{
			zoomWidth = (int) (mFile.SourceWidth * zoom * 1.0);
			zoomHeight = (int) (mFile.SourceHeight * zoom * 1.0);
		}

		canvas.set_size_request(zoomWidth, zoomHeight);
		this.resize(100,50);//set a visible min size
		gtk_do_events();
	}

	private void scalePos_value_changed(){
		player.Seek(scalePos.get_value());
	}
	
	private void scalePos_value_changed_connect(){
		scalePos.value_changed.connect(scalePos_value_changed);
	}

	private void scalePos_value_changed_disconnect(){
		scalePos.value_changed.disconnect(scalePos_value_changed);
	}
	
	private void set_play_icon(){
		if (player.IsPaused){
			btnPlay.set_tooltip_text (_("Play"));
			btnPlay.image = get_shared_icon("", "media-playback-start.png", 24);
		}
		else{
			btnPlay.set_tooltip_text (_("Pause"));
			btnPlay.image = get_shared_icon("", "media-playback-pause.png", 24);
		}
		gtk_do_events();
	}
	
	private void set_mute_icon(){
		if (player.IsMuted){
			btnMute.set_tooltip_text (_("Mute"));
			btnMute.image = get_shared_icon("", "audio-muted.svg", 24);
		}
		else{
			btnMute.set_tooltip_text (_("Mute"));
			btnMute.image = get_shared_icon("", "audio-high.svg", 24);
		}
		gtk_do_events();
	}

	private void set_fullscreen_icon(){
		if (IsMaximized){
			btnFullscreen.set_tooltip_text (_("Fullscreen"));
			btnFullscreen.image = get_shared_icon("", "view-restore.png", 24);
		}
		else{
			btnFullscreen.set_tooltip_text (_("Fullscreen"));
			btnFullscreen.image = get_shared_icon("", "view-fullscreen.png", 24);
		}
		gtk_do_events();
	}

	private void status_timer_start(){
		status_timer_stop();

		tmr_status = Timeout.add(1000, status_timeout);
	}

	private void status_timer_stop(){
		if (tmr_status > 0) {
			Source.remove(tmr_status);
			tmr_status = 0;
		}
	}
	
	private bool status_timeout(){
		status_timer_stop();

		scalePos_value_changed_disconnect();
		scalePos.adjustment.value = (double) player.Position;
		scalePos_value_changed_connect();

		set_play_icon();
		set_mute_icon();

		if ((grid_trim_advanced != null) && grid_trim_advanced.visible){
			timeline_redraw();
		}
		
		gtk_do_events();

		status_timer_start();
		return true;
	}

}

