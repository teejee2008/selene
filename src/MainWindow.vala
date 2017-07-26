/*
 * MainWindow.vala
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

public class MainWindow : Gtk.Window{
	// main toolbar
	
	private Gtk.Toolbar toolbar;
	
	private Gtk.Menu menu_add_files;
	private Gtk.MenuToolButton btn_add_files;
	private Gtk.Menu menu_remove_files;
	private Gtk.MenuToolButton btn_remove_files;
	private Gtk.Menu menu_edit_files;
    private Gtk.MenuToolButton btn_edit_files;
    
    private Gtk.ToolButton btn_start;
    private Gtk.ToolButton btn_stop;
    private Gtk.ToolButton btn_finish;
    private Gtk.ToolButton btn_pause;
    private Gtk.ToggleToolButton btn_shutdown;
    private Gtk.ToolButton btn_background;
    private Gtk.SeparatorToolItem separator1;
    private Gtk.SeparatorToolItem separator2;
    private Gtk.ToolButton btn_encoders;
    private Gtk.ToolButton btn_app_settings;
    private Gtk.ToolButton btn_about;
    private Gtk.ToolButton btn_donate;
    private Gtk.ToolButton btn_open_output_dir;
    
    // presets
    
    private Gtk.Toolbar toolbar2;
    private Gtk.ToolButton btn_add_preset;
	private Gtk.ToolButton btn_remove_preset;
	private Gtk.ToolButton btn_open_preset_dir;
	private Gtk.ToolButton btn_preset_info;
	
	private Gtk.Box vbox_main;
	private Gtk.Box vbox_main_2;
	private Gtk.ComboBox cmb_script_file;
	private Gtk.ComboBox cmb_script_dir;
	private Gtk.Button btn_edit_preset;
	private Gtk.Label lbl_status;

	// right-click menu
	
	private Gtk.Menu menu_file;
	private Gtk.ImageMenuItem mi_file_info;
	private Gtk.ImageMenuItem mi_file_info_output;
	private Gtk.ImageMenuItem mi_file_skip;
	private Gtk.MenuItem mi_file_crop;
	private Gtk.MenuItem mi_file_trim;
	private Gtk.MenuItem mi_file_remove;
	private Gtk.MenuItem mi_file_play_src;
	private Gtk.MenuItem mi_file_play_output;
	private Gtk.MenuItem miFileSeparator1;
	private Gtk.MenuItem miFileSeparator2;
	private Gtk.MenuItem mi_file_open_temp_dir;
	private Gtk.MenuItem mi_file_open_output_dir;
	private Gtk.MenuItem mi_file_open_logfile;
	private Gtk.MenuItem mi_listview_columns;

	// list view columns

	private Gtk.TreeView treeview;
	private Gtk.ScrolledWindow sw_files;
	private TreeViewColumnManager tv_manager;
	
	private Gtk.TreeViewColumn col_name;
	private Gtk.TreeViewColumn col_size;
	private Gtk.TreeViewColumn col_duration;
	private Gtk.TreeViewColumn col_progress;
	private Gtk.TreeViewColumn col_spacer;
	private Gtk.TreeViewColumn col_file_format;
	private Gtk.TreeViewColumn col_aformat;
	private Gtk.TreeViewColumn col_channels;
	private Gtk.TreeViewColumn col_sampling;
	private Gtk.TreeViewColumn col_bitrate;
	private Gtk.TreeViewColumn col_abitrate;
	private Gtk.TreeViewColumn col_vbitrate;
	private Gtk.TreeViewColumn col_vformat;
	private Gtk.TreeViewColumn col_width;
	private Gtk.TreeViewColumn col_height;
	private Gtk.TreeViewColumn col_fps;
	private Gtk.TreeViewColumn col_artist;
	private Gtk.TreeViewColumn col_album;
	private Gtk.TreeViewColumn col_genre;
	private Gtk.TreeViewColumn col_track_name;
	private Gtk.TreeViewColumn col_track_num;
	private Gtk.TreeViewColumn col_comments;
	private Gtk.TreeViewColumn col_recorded_date;
	private Gtk.Grid grid_config;

	// regular expressions
	
	private Regex rex_generic;
	private Regex rex_mkvmerge;
	private Regex rex_ffmpeg;
	private Regex rex_libav;
	private Regex rex_libav_video;
	private Regex rex_libav_audio;
	private Regex rex_x264;

	// timers and status
	
	private string statusLine;
	private uint timerID = 0;
	private uint startupTimer = 0;
	private uint statusTimer = 0;
	private uint cpuUsageTimer = 0;
	
	private bool paused = false;
	private MediaFile lastFile;
	private string msg_add;
	
	private const Gtk.TargetEntry[] targets = {
		{ "text/uri-list", 0, 0}
	};

	// initialize window -----------------

	public MainWindow() {

		log_debug("MainWindow()");
		
		set_window_title();
        window_position = WindowPosition.CENTER;
        set_default_size (650, 20);
        icon = get_app_icon(16);

		Gtk.drag_dest_set (this,Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
		drag_data_received.connect(on_drag_data_received);

        //vbox_main
        vbox_main = new Box (Orientation.VERTICAL, 0);
        add (vbox_main);

		log_debug("MainWindow(): toolbar");
		
        //main toolbar
		init_ui_main_toolbar();

		log_debug("MainWindow(): listview");
		
		//listview
		init_list_view();
		refresh_list_view();
		init_list_view_context_menu();

		log_debug("MainWindow(): presets");
		
		//presets
		init_preset_toolbar();
		init_preset_dropdowns();
        populate_script_folders();
		select_script();

		log_debug("MainWindow(): statusbar");
		
		//statusbar
		init_statusbar();
		statusbar_default_message();

		log_debug("MainWindow(): regular_expressions");
		
		//regex
		init_regular_expressions();

		log_debug("MainWindow(): handlers");
		
		//destroy handler
		this.delete_event.connect (()=>{
			if (App.Status == AppStatus.IDLE){
				convert_finish();
				return true;
			}
			else{
				return false;
			}
		});

		this.destroy.connect(Gtk.main_quit);

		log_debug("MainWindow(): exit");
	}

	// toolbar -------------------------------------

	private void init_ui_main_toolbar(){
		//toolbar
		toolbar = new Gtk.Toolbar();
		toolbar.toolbar_style = ToolbarStyle.BOTH_HORIZ;
		toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		vbox_main.pack_start (toolbar, false, false, 0);

		init_ui_main_toolbar_add();

		init_ui_main_toolbar_remove();
		
		//separator
		separator1 = new Gtk.SeparatorToolItem();
		toolbar.add(separator1);

		init_ui_main_toolbar_edit();
		
		//btn_start
		btn_start = new Gtk.ToolButton.from_stock ("gtk-media-play");
		btn_start.is_important = true;
		btn_start.label = _("Start");
		btn_start.clicked.connect (start);
		btn_start.set_tooltip_text (_("Start"));
		toolbar.add (btn_start);

		//btn_pause
		btn_pause = new Gtk.ToolButton.from_stock ("gtk-media-pause");
		btn_pause.is_important = true;
		btn_pause.clicked.connect (btn_pause_clicked);
		btn_pause.set_tooltip_text (_("Pause"));
		btn_pause.visible = false;
		btn_pause.no_show_all = true;
		toolbar.add (btn_pause);

		//btn_stop
		btn_stop = new Gtk.ToolButton.from_stock ("gtk-media-stop");
		btn_stop.is_important = true;
		btn_stop.clicked.connect (btn_stop_clicked);
		btn_stop.set_tooltip_text (_("Abort"));
		btn_stop.visible = false;
		btn_stop.no_show_all = true;
		toolbar.add (btn_stop);

		//btn_background
        btn_background = new Gtk.ToolButton.from_stock ("gtk-execute");
        btn_background.label = _("Background");
        btn_background.visible = false;
        btn_background.no_show_all = true;
        btn_background.is_important = true;
        btn_background.clicked.connect (btn_background_clicked);
        btn_background.set_tooltip_text (_("Run in background with lower priority"));
        toolbar.add (btn_background);

		//btn_finish
		btn_finish = new Gtk.ToolButton.from_stock ("gtk-ok");
		btn_finish.is_important = true;
		btn_finish.label = _("Finish");
		btn_finish.clicked.connect (() => {  convert_finish(); });
		btn_finish.set_tooltip_text (_("Finish"));
		btn_finish.visible = false;
		btn_finish.no_show_all = true;
		toolbar.add (btn_finish);

		//separator
		separator2 = new Gtk.SeparatorToolItem();
		separator2.set_draw (false);
		separator2.set_expand (true);
		toolbar.add (separator2);

		//btn_app_settings
		btn_app_settings = new Gtk.ToolButton.from_stock ("gtk-preferences");
		btn_app_settings.clicked.connect (btn_app_settings_clicked);
		btn_app_settings.set_tooltip_text (_("Application Settings"));
		toolbar.add (btn_app_settings);

		//btn_encoders
		btn_encoders = new Gtk.ToolButton.from_stock ("gtk-info");
		btn_encoders.clicked.connect (btn_encoders_clicked);
		btn_encoders.set_tooltip_text (_("Encoders"));
		toolbar.add (btn_encoders);

		//btn_donate
		btn_donate = new Gtk.ToolButton.from_stock ("gtk-dialog-info");
		btn_donate.is_important = false;
		btn_donate.icon_widget = get_shared_icon("donate","donate.svg",24);
		btn_donate.label = _("Donate");
		btn_donate.set_tooltip_text (_("Donate"));
		toolbar.add(btn_donate);

		btn_donate.clicked.connect(btnDonation_clicked);

		//btn_about
		btn_about = new Gtk.ToolButton.from_stock ("gtk-about");
		btn_about.is_important = false;
		btn_about.icon_widget = get_shared_icon("gtk-about","help-info.svg",24);
		btn_about.clicked.connect (btn_about_clicked);
		btn_about.set_tooltip_text (_("About"));
		toolbar.add (btn_about);

		//btn_shutdown
		btn_shutdown = new Gtk.ToggleToolButton.from_stock ("gtk-quit");
		btn_shutdown.label = _("Shutdown");
		btn_shutdown.visible = false;
		btn_shutdown.no_show_all = true;
		btn_shutdown.is_important = true;
		btn_shutdown.clicked.connect (btn_shutdown_clicked);
		btn_shutdown.set_tooltip_text (_("Shutdown system after completion"));
		toolbar.add (btn_shutdown);

        //btn_open_output_dir
		btn_open_output_dir = new Gtk.ToolButton.from_stock ("gtk-directory");
		//btn_open_output_dir.is_important = true;
		btn_open_output_dir.label = _("Output");
		btn_open_output_dir.clicked.connect (btn_open_output_dir_click);
		btn_open_output_dir.set_tooltip_text (_("Open output folder"));
		btn_open_output_dir.visible = false;
		btn_open_output_dir.no_show_all = true;
		toolbar.add (btn_open_output_dir);
	}

	private void init_ui_main_toolbar_add(){
		// menuAdd
		menu_add_files = new Gtk.Menu();

		// miAddFile
		var miAddFile = new Gtk.MenuItem();
		miAddFile.activate.connect (() => { select_items(true); });
		menu_add_files.append(miAddFile);

		var box = new Gtk.Box(Orientation.HORIZONTAL,6);
		box.add(get_shared_icon("gtk-file","",24));
		box.add(new Gtk.Label(_("Add File(s)...")));
		miAddFile.add(box);
		
		// miAddFolder
		var miAddFolder = new Gtk.MenuItem();
		miAddFolder.activate.connect (() => { select_items(false); });
		menu_add_files.append(miAddFolder);

		box = new Gtk.Box(Orientation.HORIZONTAL,6);
		box.add(get_shared_icon("gtk-directory","",24));
		box.add(new Gtk.Label(_("Add Folder(s)...")));
		miAddFolder.add(box);

		//btn_add_files
		btn_add_files = new Gtk.MenuToolButton.from_stock ("gtk-add");
		btn_add_files.set_menu(menu_add_files);
		btn_add_files.is_important = true;
		btn_add_files.set_tooltip_text (_("Add File(s)"));
		toolbar.add (btn_add_files);

		btn_add_files.clicked.connect(()=>{
			//menu_add_files.popup (null, null, null, 0, Gtk.get_current_event_time());
			select_items(true);
		});

		menu_add_files.show_all();
	}

	private void init_ui_main_toolbar_remove(){
		// menuRemove
		menu_remove_files = new Gtk.Menu();

		// miRemoveFiles
		var miRemoveFiles = new Gtk.MenuItem();
		miRemoveFiles.activate.connect (() => { btn_remove_files_clicked(); });
		menu_remove_files.append(miRemoveFiles);

		var box = new Gtk.Box(Orientation.HORIZONTAL,6);
		box.add(get_shared_icon("gtk-remove","",24));
		box.add(new Gtk.Label(_("Remove Selected Items")));
		
		miRemoveFiles.add(box);

		// miClearList
		var miClearList = new Gtk.MenuItem();
		miClearList.set_reserve_indicator(false);
		miClearList.activate.connect (() => { btnClearFiles_clicked(); });
		menu_remove_files.append(miClearList);

		box = new Gtk.Box(Orientation.HORIZONTAL,6);
		box.add(get_shared_icon("gtk-clear","",24));
		box.add(new Gtk.Label(_("Clear List")));
		miClearList.add(box);

		//btn_remove_files
		btn_remove_files = new Gtk.MenuToolButton.from_stock ("gtk-remove");
		btn_remove_files.set_menu(menu_remove_files);
		btn_remove_files.is_important = true;
		btn_remove_files.set_tooltip_text (_("Remove File(s)"));
		toolbar.add (btn_remove_files);

		btn_remove_files.clicked.connect(()=>{
			//menu_remove_files.popup (null, null, null, 0, Gtk.get_current_event_time());
			btn_remove_files_clicked();
		});
		
		menu_remove_files.show_all();
	}

	private void init_ui_main_toolbar_edit(){
		// menu_edit_files
		menu_edit_files = new Gtk.Menu();

		// miCropVideos
		var miCropVideos = new Gtk.MenuItem();
		miCropVideos.activate.connect (() => { btnCropVideos_clicked(); });
		menu_edit_files.append(miCropVideos);

		var box = new Gtk.Box(Orientation.HORIZONTAL,6);
		//box.add(get_shared_icon("gtk-edit","",32));
		box.add(new Gtk.Label(_("Crop Videos")));
		miCropVideos.add(box);

		// miTrimDuration
		var miTrimDuration = new Gtk.MenuItem();
		miTrimDuration.set_reserve_indicator(false);
		miTrimDuration.activate.connect (() => { btnTrimDuration_clicked(); });
		menu_edit_files.append(miTrimDuration);

		box = new Gtk.Box(Orientation.HORIZONTAL,6);
		//box.add(get_shared_icon("gtk-edit","",32));
		box.add(new Gtk.Label(_("Trim Duration")));
		miTrimDuration.add(box);

		//btn_edit_files
		btn_edit_files = new Gtk.MenuToolButton.from_stock ("gtk-edit");
		btn_edit_files.label = _("Crop");
		btn_edit_files.set_menu(menu_edit_files);
		btn_edit_files.is_important = true;
		btn_edit_files.set_tooltip_text (_("Crop Videos"));
		toolbar.add (btn_edit_files);

		btn_edit_files.clicked.connect(()=>{
			//menu_edit_files.popup (null, null, null, 0, Gtk.get_current_event_time());
			btnCropVideos_clicked();
		});
		
		menu_edit_files.show_all();
	}

	// file list -------------------------------------

	private void init_list_view(){

		log_debug("MainWindow(): init_list_view()");
		
		// tv_files ---------------------------------------------------
		
		treeview = new TreeView();
		treeview.get_selection().mode = SelectionMode.MULTIPLE;
		treeview.set_tooltip_text (_("Right-click for more options"));
		treeview.headers_clickable = true;
		treeview.rules_hint = true;
		
		sw_files = new ScrolledWindow(treeview.get_hadjustment(), treeview.get_vadjustment());
		sw_files.set_shadow_type (ShadowType.ETCHED_IN);
		sw_files.add (treeview);
		sw_files.margin = 3;
		sw_files.set_size_request (-1, 300);
		vbox_main.pack_start (sw_files, true, true, 0);
	
		CellRendererText cellText;
		TreeViewColumn col;

		log_debug("MainWindow(): init_list_view(): columns");
		
		// col_name  -------------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("File");
		col.expand = true;
		col.resizable = true;
		col.clickable = true;
		col.reorderable = true;
		col.min_width = 200;
		col.sort_column_id = InputField.FILE_PATH;
		treeview.append_column(col);
		col_name = col;
		
		//icon
		CellRendererPixbuf cellThumb = new CellRendererPixbuf ();
		col.pack_start (cellThumb, false);
		col.set_attributes(cellThumb, "height", InputField.ROW_HEIGHT);
		
		//toggle
		var cell_select = new CellRendererToggle ();
		cell_select.activatable = true;
		col.pack_start (cell_select, false);
		col.set_attributes(cell_select, "height", InputField.ROW_HEIGHT);
		
		//spacer
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_attributes(cellText, "height", InputField.ROW_HEIGHT);
		
		//name
		cellText = new CellRendererText();
		cellText.ellipsize = Pango.EllipsizeMode.END;
		col.pack_start (cellText, false);
		col.set_attributes(cellText, "height", InputField.ROW_HEIGHT);
		
		//set toggle
		col.set_cell_data_func (cell_select, (cell_layout, cell, model, iter) => {
			bool selected, isChild;
			model.get (iter, InputField.IS_CHILD, out isChild, InputField.IS_SELECTED, out selected, -1);
			if (isChild){
				(cell as Gtk.CellRendererToggle).visible = true;
				(cell as Gtk.CellRendererToggle).active = selected;
			}
			else{
				(cell as Gtk.CellRendererToggle).visible = false;
			}
		});

		//toggle handler
		cell_select.toggled.connect((path) => {
			var store = (Gtk.TreeStore) treeview.model;
			bool selected, isChild;
			MediaStream stream;
			
			TreeIter iter;
			store.get_iter_from_string (out iter, path);
			store.get (iter, InputField.STREAM_REF, out stream, -1);
			store.get (iter, InputField.IS_CHILD, out isChild, -1);
			store.get (iter, InputField.IS_SELECTED, out selected, -1);

			stream.IsSelected = !selected;

			store.set(iter, InputField.IS_SELECTED, stream.IsSelected, -1);
		});

		//set icon
		col.set_cell_data_func (cellThumb, (cell_layout, cell, model, iter)=>{
			string imagePath;
			bool hasVideo, isChild;
			model.get (iter, InputField.FILE_THUMB, out imagePath, InputField.FILE_HAS_VIDEO, out hasVideo, InputField.IS_CHILD, out isChild, -1);

			Gdk.Pixbuf pixThumb = null;

			try{
				if (isChild){
					cell.visible = false;
				}
				else{
					if (App.TileView){
						pixThumb = new Gdk.Pixbuf.from_file_at_scale(imagePath,MediaFile.ThumbnailWidth,MediaFile.ThumbnailHeight,true);
					}
					else{
						if (hasVideo){
							var img = get_shared_icon("video-x-generic","video.svg",16);
							pixThumb = (img == null) ? null : img.pixbuf;
						}
						else{
							var img = get_shared_icon("audio-x-generic","audio.svg",16);
							pixThumb = (img == null) ? null : img.pixbuf;
						}
					}

					cell.visible = true;
					(cell as Gtk.CellRendererPixbuf).pixbuf = pixThumb;
				}
			}
			catch(Error e){
				log_error (e.message);
			}

			
		});

		//set name
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			string fileName, duration, formatInfo, spanStart, spanEnd;
			int64 fileSize;
			model.get (iter, InputField.FILE_NAME, out fileName, -1);
			model.get (iter, InputField.FILE_SIZE, out fileSize, -1);
			model.get (iter, InputField.FILE_DURATION, out duration, -1);

			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);
			
			spanStart = "<span foreground='#606060'>";
			spanEnd = "</span>";
			fileName = fileName.replace("&","&amp;");

			formatInfo = ((mf.FileFormat.length > 0) ? ("" + mf.FileFormat) : "")
				+ ((mf.VideoFormat.length > 0) ? (" - " + mf.VideoFormat) : "")
				+ ((mf.AudioFormat.length > 0) ? (" - " + mf.AudioFormat) : "");

			if (isChild){
				(cell as Gtk.CellRendererText).markup = fileName;
			}
			else{
				if (App.TileView){
					(cell as Gtk.CellRendererText).markup = "%s\n%s%s | %s\n%s%s".printf(fileName, spanStart, duration, format_file_size(fileSize), formatInfo, spanEnd);
				}
				else{
					(cell as Gtk.CellRendererText).text = fileName;
				}
			}
		});

		// col_size -----------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Size");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_SIZE;
		treeview.append_column(col);
		col_size = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.StreamSize > 0){
						txt = format_file_size(video.StreamSize);
					}
				}
				else if (stream is AudioStream){
					var audio = stream as AudioStream;
					if (audio.StreamSize > 0){
						txt = format_file_size(audio.StreamSize);
					}
				}
				else if (stream is TextStream){
					var text = stream as TextStream;
					if (text.StreamSize > 0){
						txt = format_file_size(text.StreamSize);
					}
				}
			}
			else{
				txt = format_file_size(mf.Size);
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_duration --------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Duration");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_DURATION;
		treeview.append_column(col);
		col_duration = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.Duration > 0){
						txt = format_duration(video.Duration);
					}
				}
				else if (stream is AudioStream){
					var audio = stream as AudioStream;
					if (audio.Duration > 0){
						txt = format_duration(audio.Duration);
					}
				}
			}
			else{
				txt = format_duration(mf.Duration);
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_file_format --------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Format");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_FFORMAT;
		treeview.append_column(col);
		col_file_format = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.Format.length > 0){
						txt = "%s".printf(video.Format);
					}
				}
				else if (stream is AudioStream){
					var audio = stream as AudioStream;
					if (audio.Format.length > 0){
						txt = "%s".printf(audio.Format);
					}
				}
				else if (stream is TextStream){
					var text = stream as TextStream;
					if (text.Format.length > 0){
						txt = "%s".printf(text.Format);
					}
				}
			}
			else{
				if (mf.FileFormat.length > 0){
					txt = "%s".printf(mf.FileFormat);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_aformat ---------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("A-Fmt");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_AFORMAT;
		treeview.append_column(col);
		col_aformat = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is AudioStream){
					var audio = stream as AudioStream;
					if (audio.Format.length > 0){
						txt = "%s".printf(audio.Format);
					}
				}
			}
			else{
				if (mf.AudioFormat.length > 0){
					txt = "%s".printf(mf.AudioFormat);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_vformat -------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("V-Fmt");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_VFORMAT;
		treeview.append_column(col);
		col_vformat = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.Format.length > 0){
						txt = "%s".printf(video.Format);
					}
				}
			}
			else{
				if (mf.VideoFormat.length > 0){
					txt = "%s".printf(mf.VideoFormat);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_channels -------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("A-Ch");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_ACHANNELS;
		treeview.append_column(col);
		col_channels = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is AudioStream){
					var audio = stream as AudioStream;
					if (audio.Channels > 0){
						txt = "%d".printf(audio.Channels);
					}
				}
			}
			else{
				if (mf.AudioChannels > 0){
					txt = "%d".printf(mf.AudioChannels);
				}
			}

			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_sampling --------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("A-Sampling");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_ARATE;
		treeview.append_column(col);
		col_sampling = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is AudioStream){
					var audio = stream as AudioStream;
					if (audio.SampleRate > 0){
						txt = "%d hz".printf(audio.SampleRate);
					}
				}
			}
			else{
				if (mf.AudioSampleRate > 0){
					txt = "%d hz".printf(mf.AudioSampleRate);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});

		// col_bitrate ----------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Bitrate");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_BITRATE;
		treeview.append_column(col);
		col_bitrate = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.BitRate > 0){
						txt = "%d k".printf(video.BitRate);
					}
				}
				else if (stream is AudioStream){
					var audio = stream as AudioStream;
					if (audio.BitRate > 0){
						txt = "%d k".printf(audio.BitRate);
					}
				}
			}
			else{
				if (mf.BitRate > 0){
					txt = "%d k".printf(mf.BitRate);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_abitrate -------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("A-Bitrate");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_ABITRATE;
		treeview.append_column(col);
		col_abitrate = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is AudioStream){
					var audio = stream as AudioStream;
					if (audio.BitRate > 0){
						txt = "%d k".printf(audio.BitRate);
					}
				}
			}
			else{
				if (mf.AudioBitRate > 0){
					txt = "%d k".printf(mf.AudioBitRate);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});

/*
		//colVFrameSize
		colVFrameSize = new TreeViewColumn();
		colVFrameSize.title = _("Video Size");
		treeview.append_column(colVFrameSize);
		
		cellText = new CellRendererText();
		colVFrameSize.pack_start (cellText, false);
		col_aformat.set_cell_data_func (cellText, (cell_layout, cell, model, iter) => {
			MediaFile mf;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			(cell as Gtk.CellRendererText).text = ((mf.SourceWidth > 0) && (mf.SourceHeight > 0)) ? "%dx%d".printf(mf.SourceWidth,mf.SourceHeight) : "";
		});
*/

		// col_vbitrate -----------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("V-Bitrate");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_VBITRATE;
		treeview.append_column(col);
		col_vbitrate = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.BitRate > 0){
						txt = "%d k".printf(video.BitRate);
					}
				}
			}
			else{
				if (mf.VideoBitRate > 0){
					txt = "%d k".printf(mf.VideoBitRate);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_width ---------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("V-Width");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_VWIDTH;
		treeview.append_column(col);
		col_width = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.Width > 0){
						txt = "%d".printf(video.Width);
					}
				}
			}
			else{
				if (mf.SourceWidth > 0){
					txt = "%d".printf(mf.SourceWidth);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_height -------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("V-Height");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_VHEIGHT;
		treeview.append_column(col);
		col_height = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.Height > 0){
						txt = "%d".printf(video.Height);
					}
				}
			}
			else{
				if (mf.SourceHeight > 0){
					txt = "%d".printf(mf.SourceHeight);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_fps ------------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("V-Fps");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_VRATE;
		treeview.append_column(col);
		col_fps = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (isChild){
				if (stream is VideoStream){
					var video = stream as VideoStream;
					if (video.FrameRate > 0){
						txt = "%.3f".printf(video.FrameRate);
					}
				}
			}
			else{
				if (mf.SourceFrameRate > 0){
					txt = "%.3f".printf(mf.SourceFrameRate);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});

		// col_artist --------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Artist");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_ARTIST;
		treeview.append_column(col);
		col_artist = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (!isChild){
				if (mf.Artist.length > 0){
					txt = "%s".printf(mf.Artist);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});

		// col_album -----------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Album");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_ALBUM;
		treeview.append_column(col);
		col_album = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (!isChild){
				if (mf.Album.length > 0){
					txt = "%s".printf(mf.Album);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_genre ---------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Genre");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_GENRE;
		treeview.append_column(col);
		col_genre = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (!isChild){
				if (mf.Genre.length > 0){
					txt = "%s".printf(mf.Genre);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_track_name ------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Title");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_TRACK_NAME;
		treeview.append_column(col);
		col_track_name = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (!isChild){
				if (mf.TrackName.length > 0){
					txt = "%s".printf(mf.TrackName);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_track_num --------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Track #");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_TRACK_NUM;
		treeview.append_column(col);
		col_track_num = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (!isChild){
				if (mf.TrackNumber.length > 0){
					txt = "%s".printf(mf.TrackNumber);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_comments ------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Comments");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_COMMENTS;
		treeview.append_column(col);
		col_comments = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (!isChild){
				if (mf.Comment.length > 0){
					txt = "%s".printf(mf.Comment);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_recorded_date ----------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Recorded Date");
		col.clickable = true;
		col.reorderable = true;
		col.sort_column_id = InputField.FILE_RECORDED_DATE;
		treeview.append_column(col);
		col_recorded_date = col;
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 1.0;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			MediaStream stream;
			bool isChild;
			model.get (iter, InputField.FILE_REF, out mf, -1);
			model.get (iter, InputField.STREAM_REF, out stream, -1);
			model.get (iter, InputField.IS_CHILD, out isChild, -1);

			string txt = "";
			
			if (!isChild){
				if (mf.RecordedDate.length > 0){
					txt = "%s".printf(mf.RecordedDate);
				}
			}
			
			(cell as Gtk.CellRendererText).text = txt;
		});
		
		// col_progress --------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Status");
		col.fixed_width = 150;
		treeview.append_column(col);
		col_progress = col;
		
		CellRendererProgress2 cellProgress = new CellRendererProgress2();
		cellProgress.height = 15;
		cellProgress.width = 150;
		col.pack_start (cellProgress, false);
		col.set_attributes(cellProgress, "value", InputField.FILE_PROGRESS, "text", InputField.FILE_PROGRESS_TEXT);
		
		// col_spacer ----------------------------------------------
		
		col = new TreeViewColumn();
		col.expand = false;
		col.fixed_width = 10;
		treeview.append_column(col);
		col_spacer = col;
		
		cellText = new CellRendererText();
		col.pack_start (cellText, false);

		// init ----------------------------------------------------
		
		init_column_manager();

		startupTimer = Timeout.add (100,() => {
			//col_progress.visible = false;
			Source.remove (startupTimer);
			return true;
		});

		Gtk.drag_dest_set (treeview, Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
        treeview.drag_data_received.connect(on_drag_data_received);
	}

	private void init_list_view_context_menu(){

		log_debug("MainWindow(): init_list_view_context_menu()");
		
		Gdk.RGBA gray = Gdk.RGBA();
		gray.parse ("rgba(200,200,200,1)");

		// menu_file
		menu_file = new Gtk.Menu();

		// mi_file_skip
		mi_file_skip = new ImageMenuItem.from_stock ("gtk-stop", null);
		mi_file_skip.label = _("Skip File");
		mi_file_skip.activate.connect (() => { App.stop_file(); });
		menu_file.append(mi_file_skip);

		// mi_file_crop
		mi_file_crop = new Gtk.MenuItem.with_label (_("Crop Video") + "...");
		mi_file_crop.activate.connect(mi_file_crop_clicked);
		menu_file.append(mi_file_crop);

		// mi_file_trim
		mi_file_trim = new Gtk.MenuItem.with_label (_("Trim Duration") + "...");
		mi_file_trim.activate.connect(mi_file_trim_clicked);
		menu_file.append(mi_file_trim);

		// miFileSeparator0
		var miFileSeparator0 = new Gtk.MenuItem();
		//miFileSeparator0.override_color (StateFlags.NORMAL, gray);
		menu_file.append(miFileSeparator0);

		mi_file_crop.show.connect(()=>{
			miFileSeparator0.visible = (mi_file_crop.visible || mi_file_trim.visible);
		});

		mi_file_crop.hide.connect(()=>{
			miFileSeparator0.visible = (mi_file_crop.visible || mi_file_trim.visible);
		});

		mi_file_trim.show.connect(()=>{
			miFileSeparator0.visible = (mi_file_crop.visible || mi_file_trim.visible);
		});

		mi_file_trim.hide.connect(()=>{
			miFileSeparator0.visible = (mi_file_crop.visible || mi_file_trim.visible);
		});
		
		// mi_file_remove
		mi_file_remove = new ImageMenuItem.from_stock("gtk-remove", null);
		mi_file_remove.activate.connect(mi_file_remove_clicked);
		menu_file.append(mi_file_remove);

		// miFileSeparator1
		miFileSeparator1 = new Gtk.MenuItem();
		//miFileSeparator1.override_color (StateFlags.NORMAL, gray);
		menu_file.append(miFileSeparator1);

		// mi_file_open_temp_dir
		mi_file_open_temp_dir = new ImageMenuItem.from_stock("gtk-directory", null);
		mi_file_open_temp_dir.label = _("Open Temp Folder");
		mi_file_open_temp_dir.activate.connect(mi_file_open_temp_dir_clicked);
		menu_file.append(mi_file_open_temp_dir);

		// mi_file_open_output_dir
		mi_file_open_output_dir = new ImageMenuItem.from_stock("gtk-directory", null);
		mi_file_open_output_dir.label = _("Open Output Folder");
		mi_file_open_output_dir.activate.connect(mi_file_open_output_dir_clicked);
		menu_file.append(mi_file_open_output_dir);

		// mi_file_open_logfile
		mi_file_open_logfile = new ImageMenuItem.from_stock("gtk-info", null);
		mi_file_open_logfile.label = _("Open Log File");
		mi_file_open_logfile.activate.connect(mi_file_open_logfile_clicked);
		menu_file.append(mi_file_open_logfile);

		// miFileSeparator2
		miFileSeparator2 = new Gtk.MenuItem();
		//miFileSeparator2.override_color (StateFlags.NORMAL, gray);
		menu_file.append(miFileSeparator2);

		// mi_file_play_src
		mi_file_play_src = new ImageMenuItem.from_stock("gtk-media-play", null);
		mi_file_play_src.label = _("Play File (Source)");
		mi_file_play_src.activate.connect(mi_file_play_src_clicked);
		menu_file.append(mi_file_play_src);

		// mi_file_play_output
		mi_file_play_output = new ImageMenuItem.from_stock("gtk-media-play", null);
		mi_file_play_output.label = _("Play File (Output)");
		mi_file_play_output.activate.connect(mi_file_play_output_clicked);
		menu_file.append(mi_file_play_output);

		// mi_file_info
		mi_file_info = new ImageMenuItem.from_stock("gtk-properties", null);
		mi_file_info.label = _("File Info (Source)");
		mi_file_info.activate.connect(mi_file_info_clicked);
		menu_file.append(mi_file_info);

		// mi_file_info_output
		mi_file_info_output = new ImageMenuItem.from_stock("gtk-properties", null);
		mi_file_info_output.label = _("File Info (Output)");
		mi_file_info_output.activate.connect(mi_file_info_output_clicked);
		menu_file.append(mi_file_info_output);

		// miFileSeparator3
		var miFileSeparator3 = new Gtk.MenuItem();
		//miFileSeparator3.override_color (StateFlags.NORMAL, gray);
		menu_file.append(miFileSeparator3);
		
		// mi_listview_columns
		mi_listview_columns = new ImageMenuItem.from_stock("gtk-select", null);
		mi_listview_columns.label = _("Columns...");
		menu_file.append(mi_listview_columns);
		mi_listview_columns.activate.connect(()=>{
			var dlg = new ColumnSelectionDialog.with_parent(this, tv_manager);
			dlg.show_all();
			//dlg.close();
			//dlg.destroy();
			//tv_manager.set_columns(App.selected_columns);
		});

		mi_listview_columns.show.connect(()=>{
			miFileSeparator3.visible = mi_listview_columns.visible;
		});

		mi_listview_columns.hide.connect(()=>{
			miFileSeparator3.visible = mi_listview_columns.visible;
		});
		
		menu_file.show_all();

		//connect signal for shift+F10
        treeview.popup_menu.connect(() => { return menu_file_popup (menu_file, null); });
        //connect signal for right-click
		treeview.button_press_event.connect ((w, event) => {
			if (event.button == 3) {
				return menu_file_popup (menu_file, event);
			}

			return false;
		});
	}

	private void refresh_list_view (bool refresh_model = true){

		log_debug("MainWindow(): refresh_list_view()");
		
		if (refresh_model){
			var inputStore = new Gtk.TreeStore (32,  
				typeof(MediaFile), 	//FILE_REF
				typeof(MediaStream),//STREAM_REF
				typeof(bool), 		//IS_CHILD
				typeof(bool), 		//IS_SELECTED
				typeof(string), 	//FILE_PATH
				typeof(string), 	//FILE_NAME
				typeof(int64), 		//FILE_SIZE
				typeof(string),		//FILE_DURATION
				typeof(string),		//FILE_STATUS
				typeof(int), 		//FILE_PROGRESS
				typeof(string), 	//FILE_PROGRESS_TEXT
				typeof(string), 	//FILE_THUMB
				typeof(bool), 		//FILE_HAS_VIDEO
				typeof(string), 	//FILE_FFORMAT
				typeof(string), 	//FILE_AFORMAT
				typeof(string), 	//FILE_VFORMAT
				typeof(int), 		//FILE_ACHANNELS
				typeof(int), 		//FILE_ARATE
				typeof(int), 		//FILE_ABITRATE
				typeof(int), 		//FILE_VWIDTH
				typeof(int), 		//FILE_VHEIGHT
				typeof(double),		//FILE_VRATE
				typeof(int), 		//FILE_VBITRATE
				typeof(int), 		//FILE_BITRATE
				typeof(string),		//FILE_ARTIST
				typeof(string),		//FILE_ALBUM
				typeof(string),		//FILE_GENRE
				typeof(string),		//FILE_TRACK_NAME
				typeof(string),		//FILE_TRACK_NUM
				typeof(string),		//FILE_COMMENTS
				typeof(string),		//FILE_RECORDED_DATE
				typeof(int)         //ROW_HEIGHT
				);

			TreeIter iter, iter2;
			foreach(var mFile in App.InputFiles) {
				inputStore.append (out iter, null);
				inputStore.set (iter, InputField.FILE_REF, 			mFile);
				inputStore.set (iter, InputField.STREAM_REF,		null);
				inputStore.set (iter, InputField.IS_CHILD, 			false);
				inputStore.set (iter, InputField.IS_SELECTED, 		false);
				inputStore.set (iter, InputField.FILE_PATH, 		mFile.Path);
				inputStore.set (iter, InputField.FILE_NAME, 		mFile.Name);
				inputStore.set (iter, InputField.FILE_SIZE, 		mFile.Size);
				inputStore.set (iter, InputField.FILE_DURATION, 	format_duration(mFile.Duration));
				inputStore.set (iter, InputField.FILE_STATUS, 		"gtk-media-pause");
				inputStore.set (iter, InputField.FILE_PROGRESS, 	mFile.ProgressPercent);
				inputStore.set (iter, InputField.FILE_PROGRESS_TEXT, mFile.ProgressText);
				inputStore.set (iter, InputField.FILE_THUMB, 		mFile.ThumbnailImagePath);
				inputStore.set (iter, InputField.FILE_HAS_VIDEO, 	mFile.HasVideo);
				inputStore.set (iter, InputField.FILE_FFORMAT, 		mFile.FileFormat);
				inputStore.set (iter, InputField.FILE_AFORMAT, 		mFile.AudioFormat);
				inputStore.set (iter, InputField.FILE_VFORMAT, 		mFile.VideoFormat);
				inputStore.set (iter, InputField.FILE_ACHANNELS, 	mFile.AudioChannels);
				inputStore.set (iter, InputField.FILE_ARATE, 		mFile.AudioSampleRate);
				inputStore.set (iter, InputField.FILE_ABITRATE, 	mFile.AudioBitRate);
				inputStore.set (iter, InputField.FILE_VWIDTH, 		mFile.SourceWidth);
				inputStore.set (iter, InputField.FILE_VHEIGHT, 		mFile.SourceHeight);
				inputStore.set (iter, InputField.FILE_VRATE, 		mFile.SourceFrameRate);
				inputStore.set (iter, InputField.FILE_VBITRATE, 	mFile.VideoBitRate);
				inputStore.set (iter, InputField.FILE_BITRATE, 		mFile.BitRate);
				inputStore.set (iter, InputField.FILE_ARTIST, 		mFile.Artist);
				inputStore.set (iter, InputField.FILE_ALBUM, 		mFile.Album);
				inputStore.set (iter, InputField.FILE_GENRE, 		mFile.Genre);
				inputStore.set (iter, InputField.FILE_TRACK_NAME, 	mFile.TrackName);
				inputStore.set (iter, InputField.FILE_TRACK_NUM, 	mFile.TrackNumber);
				inputStore.set (iter, InputField.FILE_COMMENTS, 	mFile.Comment);
				inputStore.set (iter, InputField.FILE_RECORDED_DATE, 	mFile.RecordedDate);

				if (App.TileView){
					inputStore.set (iter, InputField.ROW_HEIGHT, MediaFile.ThumbnailHeight + 2);
				}
				else{
					inputStore.set (iter, InputField.ROW_HEIGHT, 2);
				}
				
				//if ((mFile.video_list.size < 2) && (mFile.audio_list.size < 2) && (mFile.text_list.size < 2)){
					//continue;
				//}

				if (App.Status == AppStatus.NOTSTARTED){
					foreach(MediaStream stream in mFile.stream_list) {
						if (!((stream is AudioStream)||(stream is VideoStream)||(stream is TextStream))){
							continue;
						}
						
						string desc = "";
						if (stream is VideoStream){
							desc = _("Video") + " #%d : %s".printf(stream.TypeIndex, stream.description);
						}
						else if (stream is AudioStream){
							desc = _("Audio") + " #%d : %s".printf(stream.TypeIndex, stream.description);
						}
						else if (stream is TextStream){
							desc = _("Subtitle") + " #%d : %s".printf(stream.TypeIndex, stream.description);
						}
						
						inputStore.append (out iter2, iter);
						inputStore.set (iter2, InputField.FILE_REF, 		mFile);
						inputStore.set (iter2, InputField.STREAM_REF,		stream);
						inputStore.set (iter2, InputField.IS_CHILD, 		true);
						inputStore.set (iter2, InputField.IS_SELECTED, 		stream.IsSelected);
						inputStore.set (iter2, InputField.FILE_PATH, 		mFile.Path);
						inputStore.set (iter2, InputField.FILE_NAME, 		desc);
						inputStore.set (iter2, InputField.FILE_SIZE, 		mFile.Size);
						inputStore.set (iter2, InputField.FILE_DURATION, 	format_duration(mFile.Duration));
						inputStore.set (iter2, InputField.FILE_STATUS, 		"gtk-media-pause");
						inputStore.set (iter2, InputField.FILE_PROGRESS, 	mFile.ProgressPercent);
						inputStore.set (iter2, InputField.FILE_PROGRESS_TEXT, mFile.ProgressText);
						inputStore.set (iter2, InputField.FILE_THUMB, 		mFile.ThumbnailImagePath);
						inputStore.set (iter2, InputField.FILE_HAS_VIDEO, 	mFile.HasVideo);
						inputStore.set (iter2, InputField.FILE_FFORMAT, 	mFile.FileFormat);
						inputStore.set (iter2, InputField.FILE_AFORMAT, 	mFile.AudioFormat);
						inputStore.set (iter2, InputField.FILE_VFORMAT, 	mFile.VideoFormat);
						inputStore.set (iter2, InputField.FILE_ACHANNELS, 	mFile.AudioChannels);
						inputStore.set (iter2, InputField.FILE_ARATE, 		mFile.AudioSampleRate);
						inputStore.set (iter2, InputField.FILE_ABITRATE, 	mFile.AudioBitRate);
						inputStore.set (iter2, InputField.FILE_VWIDTH, 		mFile.SourceWidth);
						inputStore.set (iter2, InputField.FILE_VHEIGHT, 	mFile.SourceHeight);
						inputStore.set (iter2, InputField.FILE_VRATE, 		mFile.SourceFrameRate);
						inputStore.set (iter2, InputField.FILE_VBITRATE, 	mFile.VideoBitRate);
						inputStore.set (iter2, InputField.FILE_BITRATE, 	mFile.BitRate);
						inputStore.set (iter2, InputField.FILE_ARTIST, 		mFile.Artist);
						inputStore.set (iter2, InputField.FILE_ALBUM, 		mFile.Album);
						inputStore.set (iter2, InputField.FILE_GENRE, 		mFile.Genre);
						inputStore.set (iter2, InputField.FILE_TRACK_NAME, 	mFile.TrackName);
						inputStore.set (iter2, InputField.FILE_TRACK_NUM, 	mFile.TrackNumber);
						inputStore.set (iter2, InputField.FILE_COMMENTS, 	mFile.Comment);
						inputStore.set (iter2, InputField.FILE_RECORDED_DATE, 	mFile.RecordedDate);
						inputStore.set (iter2, InputField.ROW_HEIGHT, 	2);
					}
				}
			}

			treeview.set_model (inputStore);
		}

		if (App.TileView){
			if (App.Status == AppStatus.NOTSTARTED){
				tv_manager.set_columns("name,spacer");
			}
			else{
				tv_manager.set_columns("name,progress,spacer");
			}
		}
		else{
			if (App.Status == AppStatus.NOTSTARTED){
				tv_manager.set_columns(App.selected_columns);
			}
			else{
				tv_manager.set_columns("name,size,duration,progress,spacer");
			}
		}
		
		//set visibility - column header
		treeview.headers_visible = !App.TileView;

		treeview.columns_autosize();

		log_debug("MainWindow(): refresh_list_view(): exit");
	}

	private enum InputField{
		FILE_REF,
		STREAM_REF,
		IS_CHILD,
		IS_SELECTED,
		FILE_PATH,
		FILE_NAME,
		FILE_SIZE,
		FILE_DURATION,
		FILE_STATUS,
		FILE_PROGRESS,
		FILE_PROGRESS_TEXT,
		FILE_THUMB,
		FILE_HAS_VIDEO,
		FILE_FFORMAT,
		FILE_AFORMAT,
		FILE_VFORMAT,
		FILE_ACHANNELS,
		FILE_ARATE,
		FILE_ABITRATE,
		FILE_VWIDTH,
		FILE_VHEIGHT,
		FILE_VRATE,
		FILE_VBITRATE,
		FILE_BITRATE,
		FILE_ARTIST,
		FILE_ALBUM,
		FILE_GENRE,
		FILE_TRACK_NAME,
		FILE_TRACK_NUM,
		FILE_COMMENTS,
		FILE_RECORDED_DATE,
		ROW_HEIGHT
	}
	
	// presets -------------------------------------
	
	private void init_preset_toolbar(){
		// Preset tool bar --------------------------------------

        //toolbar
		toolbar2 = new Gtk.Toolbar();
		toolbar2.toolbar_style = ToolbarStyle.BOTH_HORIZ;
		//toolbar2.margin_top = 3;
		toolbar2.set_icon_size(IconSize.SMALL_TOOLBAR);
		vbox_main.add (toolbar2);

		//btn_add_preset
		btn_add_preset = new Gtk.ToolButton.from_stock ("gtk-new");
		btn_add_preset.is_important = true;
		btn_add_preset.label = _("New Preset");
		btn_add_preset.clicked.connect (btn_add_preset_clicked);
		btn_add_preset.set_tooltip_text (_("Add New Preset"));
		toolbar2.add (btn_add_preset);

		//btn_remove_preset
		btn_remove_preset = new Gtk.ToolButton.from_stock ("gtk-delete");
		btn_remove_preset.is_important = true;
		btn_remove_preset.clicked.connect (btn_remove_preset_clicked);
		btn_remove_preset.set_tooltip_text (_("Delete Preset"));
		toolbar2.add (btn_remove_preset);

		//btn_open_preset_dir
		btn_open_preset_dir = new Gtk.ToolButton.from_stock ("gtk-directory");
		btn_open_preset_dir.is_important = true;
		btn_open_preset_dir.label = _("Browse");
		btn_open_preset_dir.clicked.connect (btn_open_preset_dir_clicked);
		btn_open_preset_dir.set_tooltip_text (_("Open Folder"));
		toolbar2.add (btn_open_preset_dir);

		//btn_preset_info
		btn_preset_info = new Gtk.ToolButton.from_stock ("gtk-info");
		btn_preset_info.is_important = true;
		btn_preset_info.margin_right = 6;
		btn_preset_info.label = _("Info");
		btn_preset_info.clicked.connect (btn_preset_info_clicked);
		btn_preset_info.set_tooltip_text (_("Info"));
		toolbar2.add (btn_preset_info);
	}

	private void init_preset_dropdowns(){
		//vbox_main_2
        vbox_main_2 = new Box (Orientation.VERTICAL, 0);
		vbox_main_2.margin_left = 6;
        vbox_main_2.margin_right = 6;
        vbox_main.add (vbox_main_2);

        //grid_config
        grid_config = new Grid();
        grid_config.set_column_spacing (6);
        grid_config.set_row_spacing (6);
        grid_config.visible = false;
        grid_config.margin_top = 6;
        grid_config.margin_bottom = 6;
        vbox_main_2.add (grid_config);

		//lbl_script_dir
		var lbl_script_dir = new Gtk.Label(_("Folder"));
		lbl_script_dir.xalign = (float) 0.0;
		grid_config.attach(lbl_script_dir,0,0,1,1);

        //cmb_script_dir
		cmb_script_dir = new ComboBox();
		CellRendererText cellScriptFolder = new CellRendererText();
        cmb_script_dir.pack_start( cellScriptFolder, false );
        cmb_script_dir.set_cell_data_func (cellScriptFolder, cellScriptFolder_render);
        cmb_script_dir.set_size_request(100,-1);
		cmb_script_dir.set_tooltip_text (_("Folder"));
		cmb_script_dir.changed.connect(cmb_script_dir_changed);
		grid_config.attach(cmb_script_dir,1,0,1,1);

		//lbl_script_file
		var lbl_script_file = new Gtk.Label(_("Preset"));
		lbl_script_file.xalign = (float) 0.0;
		grid_config.attach(lbl_script_file,0,1,1,1);

		//cmb_script_file
		cmb_script_file = new ComboBox();
		cmb_script_file.hexpand = true;
		CellRendererText cellScriptFile = new CellRendererText();
        cmb_script_file.pack_start( cellScriptFile, false );
        cmb_script_file.set_cell_data_func (cellScriptFile, cellScriptFile_render);
        cmb_script_file.set_tooltip_text (_("Encoding Script or Preset File"));
        cmb_script_file.changed.connect(cmb_script_file_changed);
        grid_config.attach(cmb_script_file,1,1,1,1);

		//btn_edit_preset
		btn_edit_preset = new Button.with_label("");
		btn_edit_preset.always_show_image = true;
		btn_edit_preset.image = new Gtk.Image.from_file(App.SharedImagesFolder + "/video-edit.png");
		//btn_edit_preset.image_position = PositionType.TOP;
		//btn_edit_preset.set_size_request(64,64);
		btn_edit_preset.set_tooltip_text(_("Edit Preset"));
		btn_edit_preset.clicked.connect(btn_edit_preset_clicked);
        grid_config.attach(btn_edit_preset,2,0,1,2);
	}

	private void init_statusbar(){
		//lbl_status
		lbl_status = new Label("");
		lbl_status.ellipsize = Pango.EllipsizeMode.END;
		lbl_status.margin_top = 6;
		lbl_status.margin_bottom = 6;
		vbox_main_2.add (lbl_status);
	}

	private void init_regular_expressions(){
		try{
			rex_generic = new Regex("""([0-9]+[.]?[0-9]*)%""");
			rex_mkvmerge = new Regex("""Progress: ([0-9]+[.]?[0-9]*)%""");
			rex_ffmpeg = new Regex("""time=([0-9]+[:][0-9]+[:][0-9]+[.]?[0-9]*) """);
			rex_libav = new Regex("""time=[ ]*([0-9]+[.]?[0-9]*)[ ]*""");

			//frame=   82 fps= 23 q=28.0 size=     133kB time=1.42 bitrate= 766.9kbits/s
			rex_libav_video = new Regex("""frame=[ ]*[0-9]+[ ]*fps=[ ]*([0-9]+)[.]?[0-9]*[ ]*q=[ ]*[0-9]+[.]?[0-9]*[ ]*size=[ ]*([0-9]+)kB[ ]*time=[ ]*[0-9]+[.]?[0-9]*[ ]*bitrate=[ ]*([0-9]+)[.]?[0-9]*""");

			//size=    1590kB time=30.62 bitrate= 425.3kbits/s
			rex_libav_audio = new Regex("""size=[ ]*([0-9]+)kB[ ]*time=[ ]*[0-9]+[.]?[0-9]*[ ]*bitrate=[ ]*([0-9]+)[.]?[0-9]*""");

			//[53.4%] 1652/3092 frames, 24.81 fps, 302.88 kb/s, eta 0:00:58
			rex_x264 = new Regex("""\[[0-9]+[.]?[0-9]*%\][ \t]*[0-9]+/[0-9]+[ \t]*frames,[ \t]*([0-9]+)[.]?[0-9]*[ \t]*fps,[ \t]*([0-9]+)[.]?[0-9]*[ \t]*kb/s,[ \t]*eta ([0-9:]+)""");
		}
		catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
		}
	}

	private void set_window_title(){
		title = AppName + " v" + AppVersion;
	}

	// script dropdown handlers -----------------------

	private void populate_script_folders(){
		TreeStore model = new TreeStore(2, typeof(string), typeof(string));
		cmb_script_dir.set_model(model);
		TreeIter iter0;

		model.append (out iter0, null);
		model.set (iter0, 0, App.ScriptsFolder_Custom,1, _("scripts"));
		iter_append_children (model, iter0, App.ScriptsFolder_Custom);

		model.append (out iter0, null);
		model.set (iter0, 0, App.PresetsFolder_Custom,1, _("presets"));
	    iter_append_children (model, iter0, App.PresetsFolder_Custom);
	}

	private void iter_append_children (TreeStore model, TreeIter iter0, string path){
		try{
			var dir = File.parse_name (path);
			var enumerator = dir.enumerate_children ("%s,%s".printf(FileAttribute.STANDARD_NAME,FileAttribute.STANDARD_TYPE), 0);
			FileInfo file;
			TreeIter iter1;

			while ((file = enumerator.next_file()) != null) {
				if (file.get_file_type() == FileType.DIRECTORY){
					string dirPath = dir.resolve_relative_path(file.get_name()).get_path();
					string dirName = dirPath.replace(App.UserDataDirectory + "/","");

					model.append(out iter1, null);
					model.set(iter1, 0, dirPath, 1, dirName);
					iter_append_children(model, iter1, dir.resolve_relative_path(file.get_name()).get_path());
				}
			}
		}
        catch(Error e){
	        log_error (e.message);
	    }

	}

	private void cmb_script_dir_changed(){
		//create empty model
		var model = new Gtk.ListStore(2, typeof(ScriptFile), typeof(string));
		cmb_script_file.set_model(model);

		string path = gtk_combobox_get_value(cmb_script_dir,0,"");

		try
		{
			var dir = File.parse_name (path);
	        var enumerator = dir.enumerate_children ("%s".printf(FileAttribute.STANDARD_NAME), 0);
			Gee.ArrayList<string> files = new Gee.ArrayList<string>();

	        FileInfo file;
	        while ((file = enumerator.next_file()) != null) {
				files.add(dir.resolve_relative_path(file.get_name()).get_path());
	        }
	        files.sort((a,b) => { return strcmp((string)a, (string)b); });

	        foreach(string filePath in files){
		        string fileName = File.new_for_path(filePath).get_basename();

		        if (file_exists(filePath)){
					ScriptFile sh = new ScriptFile(filePath);
					if (sh.Extension == ".sh" || sh.Extension == ".json") {
						TreeIter iter;
						model.append(out iter);
						model.set(iter, 0, sh, 1, fileName);

						if (App.SelectedScript != null && App.SelectedScript.Path == sh.Path) {
							cmb_script_file.set_active_iter(iter);
						}
					}
				}
			}

	        if (cmb_script_file.active < 0) {
				cmb_script_file.set_active(0);
			}
        }
        catch(Error e){
	        log_error (e.message);
	    }
	}

	private void cmb_script_file_changed(){
		if ((cmb_script_file == null)||(cmb_script_file.model == null)||(cmb_script_file.active < 0)){ return; }

		ScriptFile sh;
		TreeIter iter;
		cmb_script_file.get_active_iter(out iter);
		cmb_script_file.model.get (iter, 0, out sh, -1);

		App.SelectedScript = sh;
	}

	private bool select_script(){
		if ((App.SelectedScript == null)||(file_exists(App.SelectedScript.Path) == false)){
			cmb_script_dir.set_active(2);
			cmb_script_file.set_active(0);
			return false;
		}

		string filePath = App.SelectedScript.Path;

		string dirPath = GLib.Path.get_dirname(filePath);
		bool retVal = false;
		TreeIter iter;

		//select folder
		TreeStore model = (TreeStore) cmb_script_dir.model;
		for (bool next = model.get_iter_first (out iter); next; next = model.iter_next (ref iter)) {
			string path;
			model.get (iter, 0, out path);
			if (path == dirPath){
				cmb_script_dir.set_active_iter(iter);
				retVal = true;
				break;
			}
			else if(model.iter_has_child(iter)){
				retVal = select_script_recurse_children(filePath, iter);
				if (retVal) { break; }
			}
		}

		//check if selected file is in some other folder
		if (retVal == false){
			//unselect
			cmb_script_dir.set_active(-1);

			//add the selected file
			var model1 = new Gtk.ListStore(2, typeof(ScriptFile), typeof(string));
			cmb_script_file.set_model(model1);
			ScriptFile sh = new ScriptFile(filePath);
			model1.append(out iter);
			model1.set(iter, 0, sh, 1, sh.Title);

			//select it
			cmb_script_file.set_active(0);
		}

		//select file
		var model1 = (Gtk.ListStore) cmb_script_file.model;
		for (bool next = model1.get_iter_first (out iter); next; next = model1.iter_next (ref iter)) {
			ScriptFile sh = new ScriptFile(filePath);
			model1.get (iter, 0, out sh);
			if (sh.Path == filePath){
				cmb_script_file.set_active_iter(iter);
				retVal = true;
				break;
			}
		}

		return retVal;
	}

	private bool select_script_recurse_children (string filePath, TreeIter iter0){
		TreeStore model = (TreeStore) cmb_script_dir.model;
		string dirPath = GLib.Path.get_dirname(filePath);
		bool retVal = false;

		TreeIter iter1;
		int index = 0;

		for (bool next = model.iter_children (out iter1, iter0); next; next = model.iter_nth_child (out iter1, iter0, index)) {

			string path;
			model.get (iter1, 0, out path);

			if (path == dirPath){
				cmb_script_dir.set_active_iter(iter1);
				return true;
			}
			else if(model.iter_has_child(iter1)){
				retVal = select_script_recurse_children(filePath, iter1);
			}
			index++;
		}

		return retVal;
	}

	private void cellScriptFile_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		ScriptFile sh;
		model.get (iter, 0, out sh, -1);
		(cell as Gtk.CellRendererText).text = sh.Title;
	}

	private void cellScriptFolder_render (CellLayout cell_layout, CellRenderer cell,
		TreeModel model, TreeIter iter){
			
		string name;
		model.get (iter, 1, out name, -1);
		(cell as Gtk.CellRendererText).text = name;
	}

	private void btn_open_preset_dir_clicked(){
		string path;
		TreeModel model = (TreeModel) cmb_script_dir.model;
		TreeIter iter;
		cmb_script_dir.get_active_iter(out iter);
		model.get (iter, 0, out path, -1);
		exo_open_folder (path + "/");
	}

	private void mi_file_open_logfile_clicked(){
		TreeSelection selection = treeview.get_selection();

		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());

			MediaFile mf = App.InputFiles[index];
			exo_open_textfile (mf.LogFile);
		}
	}

	private void preset_create(){
		string folder = gtk_combobox_get_value(cmb_script_dir,0,"");
		var window = new EncoderConfigWindow.from_preset(this, folder, "New Preset", true);
	    window.run();

	    //App.SelectedScript will be set on click of 'Save' button
	    cmb_script_dir_changed();
	}

	private void preset_edit(){
		ScriptFile sh;
		TreeIter iter;
		cmb_script_file.get_active_iter(out iter);
		cmb_script_file.model.get (iter, 0, out sh, -1);

		if (sh.Extension == ".json") {
			var window = new EncoderConfigWindow.from_preset(this, sh.Folder, sh.Title, false);
			window.run();
			cmb_script_dir_changed();
		}
	}

	private void script_create(){
		string folder = gtk_combobox_get_value(cmb_script_dir,0,"");

		int k = 0;
		string new_script = "%s/new_script.sh".printf(folder);
		while (file_exists(new_script)){
			new_script = "%s/new_script_%d.sh".printf(folder,++k);
		}

		write_file(new_script,"");
		exo_open_textfile(new_script);

		App.SelectedScript = new ScriptFile(new_script);
		cmb_script_dir_changed();
	}

	private void script_edit(){
		ScriptFile sh;
		TreeIter iter;
		cmb_script_file.get_active_iter(out iter);
		cmb_script_file.model.get (iter, 0, out sh, -1);

		if (sh.Extension == ".sh") {
			exo_open_textfile(sh.Path);
		}
	}

	private void btn_add_preset_clicked(){
		TreeIter iter;
		string folderName;
		cmb_script_dir.get_active_iter(out iter);
		cmb_script_dir.model.get (iter, 1, out folderName, -1);

		if (folderName.has_prefix("scripts")){
			script_create();
		}
		else if (folderName.has_prefix("presets")){
			preset_create();
		}
	}

	private void btn_remove_preset_clicked(){
		if ((cmb_script_file.model != null)&&(cmb_script_file.active > -1)) {
			ScriptFile sh;
			TreeIter iter;
			cmb_script_file.get_active_iter(out iter);
			cmb_script_file.model.get (iter, 0, out sh, -1);

			file_delete(sh.Path);
			cmb_script_dir_changed();

			statusbar_show_message (_("Preset deleted") + ": " + sh.Name + "", true, true);
		}
	}

	private void btn_edit_preset_clicked(){
		if ((cmb_script_file.model == null)||(cmb_script_file.active == -1)) {
			TreeIter iter;
			string folderName;
			cmb_script_dir.get_active_iter(out iter);
			cmb_script_dir.model.get (iter, 1, out folderName, -1);

			if (folderName.has_prefix("scripts")){
				script_create();
			}
			else if (folderName.has_prefix("presets")){
				preset_create();
			}
		}
		else {

			ScriptFile sh;
			TreeIter iter;
			cmb_script_file.get_active_iter(out iter);
			cmb_script_file.model.get (iter, 0, out sh, -1);

			switch (sh.Extension){
				case ".sh":
					script_edit();
					break;
				case ".json":
					preset_edit();
					break;
			}
		}
	}

	private void btn_preset_info_clicked(){
		string msg = _("Selene supports 2 types of presets:\n\n1) JSON presets with a '.json' file extension. Clicking the Edit button on the toolbar will display a GUI for configuring the preset.\n\n2) Bash scripts with a '.sh' file extension. Clicking the Edit button will open the script file in a text editor. Bash scripts are useful if you need complete control over the encoding process. The script can use any set of commands for encoding the input files. Selene will try to parse the output and display the progress during encoding. See the sample scripts in '$HOME/.config/selene/scripts' for the syntax.");

		gtk_messagebox(_("Info"), msg, this, false);
	}

	// statusbar -------------------

    private void statusbar_show_message (string message, bool is_error = false, bool timeout = true){
			
		Gdk.RGBA red = Gdk.RGBA();
		Gdk.RGBA white = Gdk.RGBA();
		red.parse ("rgba(255,0,0,1)");
		white.parse ("rgba(0,0,0,1)");

		if (is_error)
			lbl_status.override_color (StateFlags.NORMAL, red);
		else
			lbl_status.override_color (StateFlags.NORMAL, null);

		lbl_status.label = message;

		if (timeout)
			statusbar_set_timeout();
	}

    private void statusbar_set_timeout(){
		//Source.remove (statusTimer);
		statusTimer = Timeout.add (3000, statusbar_clear);
	}

    private bool statusbar_clear(){
		//Source.remove (statusTimer);
		lbl_status.label = "";
		statusbar_default_message();
		return true;
	}

	private void statusbar_default_message(){
		switch (App.Status){
			case AppStatus.NOTSTARTED:
				if (App.InputFiles.size > 0)
					statusbar_show_message(_("Select a script from the dropdown and click 'Start' to begin"), false, false);
				else
					statusbar_show_message(_("Drag files on this window or click the 'Add' button"), false, false);
				break;

			case AppStatus.IDLE:
				statusbar_show_message(_("[Batch completed] Right-click for options or click 'Finish' to continue."), false, false);
				break;

			case AppStatus.PAUSED:
				statusbar_show_message(_("[Paused] Click 'Resume' to continue or 'Stop' to abort."), false, false);
				break;

			case AppStatus.RUNNING:
				statusbar_show_message(_("Converting") + ": '%s'".printf(App.CurrentFile.Path), false, false);
				break;
		}
	}

	// file list context menu -------------------------

    private bool menu_file_popup (Gtk.Menu popup, Gdk.EventButton? event) {
		TreeSelection selection = treeview.get_selection();
		int index = -1;
		MediaFile mFile = null;
		//if (selection.count_selected_rows() == 0){
		//	return true;
		//}

		if (selection.count_selected_rows() == 1){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			index = int.parse (path.to_string());
			mFile = App.InputFiles[index];
		}

		switch(App.Status){
			case AppStatus.NOTSTARTED:
				mi_file_skip.visible = false;
				mi_file_open_temp_dir.visible = false;
				mi_file_open_output_dir.visible = false;
				mi_file_open_logfile.visible = false;

				mi_file_info.visible = true;
				mi_file_info_output.visible = false;
				mi_file_play_src.visible = true;
				mi_file_play_output.visible = false;
				mi_file_crop.visible = true;
				mi_file_trim.visible = true;
				mi_file_remove.visible = true;
				miFileSeparator1.visible = true;
				miFileSeparator2.visible = false;
				
				mi_listview_columns.visible = !App.TileView;
				
				mi_file_info.sensitive = (selection.count_selected_rows() == 1);
				mi_file_play_src.sensitive = (selection.count_selected_rows() == 1);
				mi_file_crop.sensitive = (mFile != null) && (mFile.HasVideo);
				mi_file_trim.sensitive = (selection.count_selected_rows() == 1);
				mi_file_remove.sensitive = (selection.count_selected_rows() > 0);
				break;

			case AppStatus.RUNNING:

				mi_file_skip.visible = true;
				miFileSeparator1.visible = true;
				miFileSeparator2.visible = false;
				mi_file_open_temp_dir.visible = true;
				mi_file_open_output_dir.visible = true;
				mi_file_open_logfile.visible = false;

				mi_listview_columns.visible = false;
				
				if (selection.count_selected_rows() == 1){
					if (App.InputFiles[index].Status == FileStatus.RUNNING){
						mi_file_skip.sensitive = true;
					}
					else{
						mi_file_skip.sensitive = false;
					}
					if (dir_exists(App.InputFiles[index].TempDirectory)){
						mi_file_open_temp_dir.sensitive = true;
					}
					else{
						mi_file_open_temp_dir.sensitive = false;
					}
					mi_file_open_output_dir.sensitive = false;
				}
				else{
					mi_file_skip.sensitive = false;
					mi_file_open_temp_dir.sensitive = false;
					mi_file_open_output_dir.sensitive = false;
				}

				mi_file_info.visible = false;
				mi_file_info_output.visible = false;
				mi_file_play_src.visible = false;
				mi_file_play_output.visible = false;
				mi_file_crop.visible = false;
				mi_file_trim.visible = false;
				mi_file_remove.visible = false;
				break;

			case AppStatus.IDLE:

				mi_file_open_temp_dir.visible = true;
				mi_file_open_output_dir.visible = true;
				mi_file_open_logfile.visible = true;

				if (index != -1){
					mi_file_open_temp_dir.sensitive = true;
					mi_file_open_output_dir.sensitive = true;
				}
				else{
					mi_file_open_temp_dir.sensitive = false;
					mi_file_open_output_dir.sensitive = false;
				}

				mi_file_skip.visible = false;
				mi_file_info.visible = true;
				mi_file_info_output.visible = true;
				mi_file_play_src.visible = true;
				mi_file_play_output.visible = true;
				mi_file_crop.visible = false;
				mi_file_trim.visible = false;
				mi_file_remove.visible = false;
				miFileSeparator1.visible = false;
				miFileSeparator2.visible = true;

				mi_listview_columns.visible = false;
				
				if (selection.count_selected_rows() == 1){
					string outpath = App.InputFiles[index].OutputFilePath;
					if (outpath != null && outpath.length > 0 && file_exists(outpath)){
						mi_file_info_output.sensitive = true;
						mi_file_play_output.sensitive = true;
					}
				}
				else{
					mi_file_info_output.sensitive = false;
					mi_file_play_output.sensitive = false;
				}

				break;
		}

		if (event != null) {
			menu_file.popup (null, null, null, event.button, event.time);
		} else {
			menu_file.popup (null, null, null, 0, Gtk.get_current_event_time());
		}
		return true;
	}

    private void mi_file_info_clicked() {
		TreeSelection selection = treeview.get_selection();

		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());

			var window = new FileInfoWindow(App.InputFiles[index]);
			window.set_transient_for(this);
			window.show_all();
			window.run();
		}
    }

    private void mi_file_info_output_clicked() {
		TreeSelection selection = treeview.get_selection();

		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());

			MediaFile mf = App.InputFiles[index];

			if (file_exists(mf.OutputFilePath)){
				MediaFile mfOutput = new MediaFile(mf.OutputFilePath, App.PrimaryEncoder);
				var window = new FileInfoWindow(mfOutput);
				window.set_transient_for(this);
				window.show_all();
				window.run();
			}
		}
	}

    private void mi_file_crop_clicked() {
		TreeSelection selection = treeview.get_selection();
		if (selection.count_selected_rows() != 1){ return; }

		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);

		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];

			MediaPlayerWindow.CropVideo(mf, this);

			break;
		}
    }

	private void mi_file_trim_clicked() {
		TreeSelection selection = treeview.get_selection();
		if (selection.count_selected_rows() != 1){ return; }

		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);

		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];
			
			MediaPlayerWindow.TrimFile(mf, this);

			break;
		}
    }

    private void mi_file_remove_clicked() {
		btn_remove_files_clicked();
    }

    private void mi_file_open_temp_dir_clicked() {
		TreeSelection selection = treeview.get_selection();
		if (selection.count_selected_rows() == 0){ return; }

		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);

		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];
			exo_open_folder (mf.TempDirectory + "/");
		}
    }

    private void mi_file_open_output_dir_clicked() {
		TreeSelection selection = treeview.get_selection();
		if (selection.count_selected_rows() == 0){ return; }

		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);

		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];

			if (App.OutputDirectory.length == 0){
				exo_open_folder (mf.Location + "/");
			} else{
				exo_open_folder (App.OutputDirectory + "/");
			}
		}
    }

    private void btn_open_output_dir_click(){
		if (App.OutputDirectory.length > 0 && dir_exists(App.OutputDirectory)){
			exo_open_folder (App.OutputDirectory + "/");
		}
	}


    private void mi_file_play_output_clicked() {
		TreeSelection selection = treeview.get_selection();

		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];

			var mf_output = new MediaFile(mf.OutputFilePath, App.PrimaryEncoder);

			if (App.PrimaryGuiPlayer.length > 0){
				execute_command_script_async("%s '%s'".printf(App.PrimaryGuiPlayer, escape_single_quote(mf.OutputFilePath)));
			}
			else{
				MediaPlayerWindow.PlayFile(mf_output);
			}
		}
    }

    private void mi_file_play_src_clicked() {
		TreeSelection selection = treeview.get_selection();

		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];

			if (App.PrimaryGuiPlayer.length > 0){
				execute_command_script_async("%s '%s'".printf(App.PrimaryGuiPlayer, escape_single_quote(mf.Path)));
			}
			else{
				MediaPlayerWindow.PlayFile(mf); 
			}
		}
    }

	// add files --------------------------------

	private void select_items(bool select_files){
		Gtk.FileChooserDialog dlg = null;

		if (select_files){
			dlg = new Gtk.FileChooserDialog(_("Add File(s)"), this, Gtk.FileChooserAction.OPEN,
					"gtk-cancel", Gtk.ResponseType.CANCEL, "gtk-open", Gtk.ResponseType.ACCEPT);
		}
		else{
			dlg = new Gtk.FileChooserDialog(_("Add Folder(s)"), this, Gtk.FileChooserAction.SELECT_FOLDER,
					"gtk-cancel", Gtk.ResponseType.CANCEL, "gtk-open", Gtk.ResponseType.ACCEPT);
		}

		dlg.local_only = true;
 		dlg.set_modal (true);
 		dlg.set_select_multiple (true);

		if (App.InputDirectory.length > 0) {
			dlg.set_current_folder(App.InputDirectory);
		}

		var list = new Gee.ArrayList<string>();
		
 		if (dlg.run() == Gtk.ResponseType.ACCEPT){
			//get file list
			foreach (string item_path in dlg.get_filenames()){
				get_list_of_files_to_add(ref list, item_path);
			}
			App.InputDirectory = dlg.get_current_folder();
	 	}

		dlg.close();
		//dlg.destroy();
		gtk_do_events();

		add_items(list);
	}

	private void add_items(Gee.ArrayList<string> list){
		var status_msg = _("Reading file properties...");
		var progressDlg = new SimpleProgressWindow.with_parent(this, status_msg);
		progressDlg.set_title(_("Adding..."));
		progressDlg.show_all();
		gtk_do_events();

		//get total count
		App.progress_total = list.size;
		App.progress_count = 0;
		
		msg_add = "";
		foreach (string file_path in list){
			App.status_line = _("Adding (%d/%d): '%s'").printf(App.progress_count + 1, App.progress_total, file_basename(file_path));
			progressDlg.update_status_line();
			gtk_do_events();

			add_file(file_path);

			App.progress_count++;
			progressDlg.update_progressbar();
			gtk_do_events();
		}

		progressDlg.close();
		//progressDlg.destroy();
		gtk_do_events();

		//Adjustment adj = sw_files.get_vadjustment();
		//double pos = adj.get_value();
		//log_msg("%f".printf(treeview.vadjustment.get_value()));
		refresh_list_view();

		//adj.set_value(adj.upper-adj.page_size);
		//sw_files.set_vadjustment(adj);

		//log_msg("%f".printf(treeview.vadjustment.get_value()));

	 	if (msg_add.length > 0){
			msg_add = _("Some files could not be added:") + "\n\n" + msg_add;
			gtk_messagebox("Unknown Format",msg_add,this,true);
			msg_add = "";
		}
	}
	
	private Gee.ArrayList<string> get_list_of_files_to_add(ref Gee.ArrayList<string>? list, string item_path){
		if (list == null){
			list = new Gee.ArrayList<string>();
		}
		
		File file = File.new_for_path (item_path);
		if (file.query_exists()){
			try{
				FileInfo f_info = file.query_info("%s,%s".printf(FileAttribute.STANDARD_NAME,FileAttribute.STANDARD_TYPE), FileQueryInfoFlags.NONE);
				if (f_info.get_file_type() == FileType.REGULAR){
					list.add(item_path);
				}
				else if (f_info.get_file_type() == FileType.DIRECTORY){
					FileEnumerator f_enum = file.enumerate_children ("%s".printf(FileAttribute.STANDARD_NAME), 0);
					FileInfo f_info_child;
					while ((f_info_child = f_enum.next_file ()) != null) {
						string name = f_info_child.get_name();
						string item = item_path + "/" + name;
						get_list_of_files_to_add(ref list, item);
					}
				}
			}
			catch (Error e) {
				log_error (e.message);
			}
		}

		return list;
	}
	
	private void add_item(string item_path, bool count_only, ref int count){
		File file = File.new_for_path (item_path);
		if (file.query_exists()){
			try{
				FileInfo f_info = file.query_info("%s,%s".printf(FileAttribute.STANDARD_NAME,FileAttribute.STANDARD_TYPE), FileQueryInfoFlags.NONE);
				if (f_info.get_file_type() == FileType.REGULAR){
					count++;
					if (!count_only){
						add_file(item_path);
					}
				}
				else if (f_info.get_file_type() == FileType.DIRECTORY){
					FileEnumerator f_enum = file.enumerate_children ("%s".printf(FileAttribute.STANDARD_NAME), 0);
					FileInfo f_info_child;
					while ((f_info_child = f_enum.next_file ()) != null) {
						string name = f_info_child.get_name();
						string item = item_path + "/" + name;
						add_item(item, count_only, ref count);
					}
				}
			}
			catch (Error e) {
				log_error (e.message);
			}
		}
	}

	private void add_file(string file_path){
		var mFile = App.add_file (file_path);
		if (mFile == null){
			bool found = false;
			foreach(MediaFile mf in App.InputFiles){
				foreach(MediaStream stream in mf.text_list){
					if ((stream as TextStream).SubFile == file_path){
						found = true;
						break;
					}
				}
				if (found){
					break;
				}
			}
			if (!found){
				msg_add += "%s\n".printf(file_basename(file_path));
			}
		}

		// TODO: high: easy: remove the "some files could not be added" message from subtitles files that have been added
	}

	private void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) {
		//get file list
		var list = new Gee.ArrayList<string>();
		foreach (string uri in data.get_uris()){
			string item_path = uri.replace("file://","").replace("file:/","");
			item_path = Uri.unescape_string (item_path);
			get_list_of_files_to_add(ref list, item_path);
		}

		add_items(list);

        Gtk.drag_finish (drag_context, true, false, time);
    }

	// treeview columns --------------------------------

	private void init_column_manager(){

		// set column names
		col_name.set_data<string>("name", "name");
		col_size.set_data<string>("name", "size");
		col_duration.set_data<string>("name", "duration");
		
		col_file_format.set_data<string>("name", "format");
		col_aformat.set_data<string>("name", "aformat");
		col_vformat.set_data<string>("name", "vformat");
		col_channels.set_data<string>("name", "channels");
		col_sampling.set_data<string>("name", "samplingrate");
		col_width.set_data<string>("name", "width");
		col_height.set_data<string>("name", "height");
		col_fps.set_data<string>("name", "framerate");
		col_bitrate.set_data<string>("name", "bitrate");
		col_abitrate.set_data<string>("name", "abitrate");
		col_vbitrate.set_data<string>("name", "vbitrate");
		
		col_artist.set_data<string>("name", "artist");
		col_album.set_data<string>("name", "album");
		col_genre.set_data<string>("name", "genre");
		col_track_name.set_data<string>("name", "title");
		col_track_num.set_data<string>("name", "tracknum");
		col_comments.set_data<string>("name", "comments");
		col_recorded_date.set_data<string>("name", "recordeddate");

		col_progress.set_data<string>("name", "progress");
		col_spacer.set_data<string>("name", "spacer");

		// load default columns
		tv_manager = new TreeViewColumnManager((Gtk.TreeView) treeview,
			Main.REQUIRED_COLUMNS, Main.REQUIRED_COLUMNS_END, Main.DEFAULT_COLUMNS, Main.DEFAULT_COLUMN_ORDER);

		//tv_manager.set_columns(App.selected_columns);
	}

    // toolbar --------------------------------
    
	private void btn_remove_files_clicked(){
		Gee.ArrayList<MediaFile> list = new Gee.ArrayList<MediaFile>();
		TreeSelection sel = treeview.get_selection();

		TreeIter iter;
		bool iterExists = treeview.model.get_iter_first (out iter);
		while (iterExists) {
			if (sel.iter_is_selected (iter)){
				MediaFile mf;
				treeview.model.get (iter, InputField.FILE_REF, out mf, -1);
				list.add(mf);
			}
			iterExists = treeview.model.iter_next (ref iter);
		}

		App.remove_files(list);
		refresh_list_view();
	}

	private void btnClearFiles_clicked(){
		App.remove_all();
		refresh_list_view();
	}

	private void btnCropVideos_clicked(){
		if (App.InputFiles.size == 0){
			string title = _("No Files");
			string msg = _("Add some files to the file list");
			gtk_messagebox(title, msg, this, true);
			return;
		}

		int count = 0 ;
		foreach(var mf in App.InputFiles){
			if (mf.HasVideo){
				count++;
			}
		}
		
		if (count == 0){
			string title = _("No Videos");
			string msg = _("Add some videos to the file list");
			gtk_messagebox(title, msg, this, true);
			return;
		}

		BatchEditWindow.CropVideos(this);
		this.hide();
	}

	private void btnTrimDuration_clicked(){
		if (App.InputFiles.size == 0){
			string title = _("No Files");
			string msg = _("Add some files to the file list");
			gtk_messagebox(title, msg, this, true);
			return;
		}

		BatchEditWindow.TrimFiles(this);
		this.hide();
	}


	private void btn_about_clicked(){
		var dialog = new AboutWindow();
		dialog.set_transient_for (this);

		dialog.authors = {
			"Tony George:teejeetech@gmail.com"
		};

		dialog.translators = {
			"abuyop (Malay):launchpad.net/~abuyop",
			"B. W. Knight (Korean):launchpad.net/~kbd0651",
			"Felix Moreno (Spanish):launchpad.net/~felix-justdust",
			"Radek Otáhal (Czech):radek.otahal@email.cz",
			"Heimen Stoffels (Dutch):vistausss@outlook.com",
			"Anne017, Daniel U. Thibault, Jean-Marc. (French):https://launchpad.net/~lp-l10n-fr",
			"Gilberto vagner, Paulo Giovanni Pereira. (Brazilian Portuguese):https://launchpad.net/~lp-l10n-pt-br",
			"Åke Engelbrektson (Swedish):https://launchpad.net/~eson",
		};

		dialog.third_party = {
			"x264 by Laurent Aimar, Loren Merritt, Fiona Glaser, Anton Mitrofanov and Henrik Gramner:http://www.videolan.org/developers/x264.html",
			"x265 by MulticoreWare and the x265 development team:http://x265.org/",
			"Ogg, Opus and Theora by Xiph.org:http://www.opus-codec.org/",
			"WebM, VP8 and VP9 by On2, Xiph, Matroska and Google:http://www.webmproject.org/",
			"ffmpeg by Fabrice Bellard:http://ffmpeg.org/",
			"LAME MP3 Encoder by the LAME development team:http://lame.sourceforge.net/",
			"Nero AAC Codec by Nero AG:http://www.nero.com/enu/company/about-nero/nero-aac-codec.php",
			"SoX by Chris Bagwell and others:http://sox.sourceforge.net/",
			"MediaInfo by Jérôme Martinez:http://mediaarea.net/MediaInfo",
			"MKVToolNix by Moritz Bunkus:http://bunkus.org/videotools/mkvtoolnix/",
			"MP4Box from the GPAC project:http://gpac.io/",
			"ffmpeg2theora by Jan Gerber:http://v2v.cc/~j/ffmpeg2theora/"
		};
		
		dialog.documenters = null;
		dialog.artists = null;
		dialog.donations = null;

		dialog.program_name = AppName;
		dialog.comments = _("An audio-video converter for Linux");
		dialog.copyright = "Copyright © 2016 Tony George (%s)".printf(AppAuthorEmail);
		dialog.version = AppVersion;
		dialog.logo = get_app_icon(128);

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.website = "http://teejeetech.in";
		dialog.website_label = "http://teejeetech.blogspot.in";

		dialog.initialize();
		dialog.show_all();
	}

	private void btnDonation_clicked(){
		var dialog = new DonationWindow(this);
		//dialog.show_all();
		dialog.run();
		dialog.destroy();
	}

	private void btn_encoders_clicked(){
	    var dialog = new EncoderStatusWindow(this);
	    dialog.run();
	    dialog.destroy();
	}

	private void btn_app_settings_clicked(){
	    var win = new AppConfigWindow(this);
	    win.destroy.connect(()=>{
			refresh_list_view();
		});
	}

	private void btn_shutdown_clicked(){
		App.Shutdown = btn_shutdown.active;

		if (App.Shutdown){
			log_msg (_("Shutdown Enabled") + "\n");
		}
		else{
			log_msg (_("Shutdown Disabled") + "\n");
		}
	}

	private void btn_background_clicked(){
		App.BackgroundMode = true;
		App.set_priority();
		this.iconify();
	}

	private void btn_pause_clicked(){
		// pause or resume based on value of field 'pause'
	    if (App.Status == AppStatus.RUNNING){
			App.pause();
		}
		else if (App.Status == AppStatus.PAUSED){
			App.resume();
		}

		// set button statepause or resume based on value of field 'pause'
		switch (App.Status){
			case AppStatus.PAUSED:
				btn_pause.label = _("Resume");
				btn_pause.stock_id = "gtk-media-play";
				btn_pause.set_tooltip_text (_("Resume"));
				statusbar_default_message();
				break;
			case AppStatus.RUNNING:
				btn_pause.label = _("Pause");
				btn_pause.stock_id = "gtk-media-pause";
				btn_pause.set_tooltip_text (_("Pause"));
				statusbar_default_message();
				break;
		}

		update_status_all();
	}

	private void btn_stop_clicked(){
		App.stop_batch();
		update_status_all();
	}

	// encoding ----------------------------------

	private void start(){
		if (App.InputFiles.size == 0){
			string title = _("No Files");
			string msg = _("Add some files to the file list");
			gtk_messagebox(title, msg, this, true);
			return;
		}

		ScriptFile sh;
		TreeIter iter;
		cmb_script_file.get_active_iter(out iter);
		cmb_script_file.model.get (iter, 0, out sh, -1);
	    App.SelectedScript = sh;

	    //check if encoders used by preset are available
		foreach(string enc in App.get_encoder_list()){
			App.Encoders[enc].CheckAvailability();
			if (!App.Encoders[enc].IsAvailable){
				gtk_messagebox(_("Missing Encoders"), _("Following encoders were not found on your system:") + "\n\n%s\n\n".printf(App.Encoders[enc].Command)+ _("Please install required packages or select another preset"),this, true);
				return;
			}
		}

		convert_prepare();
	    App.convert_begin();

	    timerID = Timeout.add (500, update_status);
	}

	private void convert_prepare(){
		App.Status = AppStatus.RUNNING;
		refresh_list_view();
		
		toolbar2.visible = false;
		grid_config.visible = false;
		btn_shutdown.active = App.Shutdown;

		btn_shutdown.visible = App.AdminMode;
		btn_background.visible = true;
        btn_open_output_dir.visible = dir_exists(App.OutputDirectory);

		btn_edit_files.visible = false;
		btn_start.visible = false;
		btn_add_files.visible = true;
		btn_remove_files.visible = false;
		btn_app_settings.visible = false;
		btn_encoders.visible = false;
		btn_donate.visible = false;
		btn_about.visible = false;

		btn_shutdown.visible = App.AdminMode;
        btn_shutdown.active = App.Shutdown;

		btn_pause.visible = true;
		btn_stop.visible = true;
		btn_finish.visible = false;

		paused = false;
		btn_pause.stock_id = "gtk-media-pause";

		//colCrop.visible = false;
		//col_progress.visible = true;

		start_cpu_usage_timer();
	}

	private void convert_finish(){
		toolbar2.visible = true;
		grid_config.visible = true;

		//show extra columns
		//if (!App.TileView){
		//	tv_manager.set_columns(App.selected_columns);
		//}
		//colCrop.visible = !App.TileView;
		//col_progress.visible = false;

		btn_edit_files.visible = true;
		btn_start.visible = true;
		btn_add_files.visible = true;
		btn_remove_files.visible = true;
		btn_app_settings.visible = true;
		btn_encoders.visible = true;
		btn_donate.visible = true;
		btn_about.visible = true;

		btn_shutdown.visible = false;
		btn_background.visible = false;
		btn_open_output_dir.visible = false;

		btn_pause.visible = false;
		btn_stop.visible = false;
		btn_finish.visible = false;
		separator1.visible = true;

		App.convert_finish();

		refresh_list_view();
		
		statusbar_default_message();
	}

	private bool update_status(){
		TreeIter iter;
		var model = (Gtk.TreeStore)treeview.model;

		switch (App.Status) {
			case AppStatus.PAUSED:
				/*if (btn_pause.active == false){
					btn_pause.active = true;
				}*/
				break;

			case AppStatus.IDLE:
				// remove progress timers
				Source.remove (timerID);

				// check shutdown flag
				if (App.Shutdown){
					string msg = _("System will shutdown in one minute!") + "\n";
					msg += _("Press 'Cancel' to abort shutdown");
					var dialog = new Gtk.MessageDialog(null,Gtk.DialogFlags.MODAL,Gtk.MessageType.INFO, Gtk.ButtonsType.CANCEL, msg);
					dialog.set_title(_("System shutdown"));

					uint shutdownTimerID = Timeout.add (60000, shutdown);
					App.WaitingForShutdown = true;
					if (dialog.run() == Gtk.ResponseType.CANCEL){
						Source.remove (shutdownTimerID);
						App.WaitingForShutdown = false;
						stdout.printf (_("System shutdown was cancelled by user!") + "\n");
						dialog.destroy();
					}
				}

				// update status for all files
				update_status_all();

				// update UI
				btn_shutdown.visible = false;
				btn_background.visible = false;
				btn_start.visible = false;
				btn_pause.visible = false;
				btn_stop.visible = false;
				btn_add_files.visible = false;
				separator1.visible = false;
				btn_finish.visible = true;

				// update statusbar message
				statusbar_default_message();

				//stop cpu usage display
				stop_cpu_usage_timer();
				set_window_title();

				this.present();

				break;

			case AppStatus.RUNNING:
				statusLine = App.StatusLine;
				if(statusLine == null){ return false; }

				/*if (btn_pause.active){
					btn_pause.active = false;
				}
				*/

				if (lastFile == null) { lastFile = App.CurrentFile; }
				if (lastFile != App.CurrentFile){
					update_status_all();
					lastFile = App.CurrentFile;
				}

				if (model.get_iter_from_string (out iter, App.InputFiles.index_of(App.CurrentFile).to_string())){
					model.set (iter, InputField.FILE_PROGRESS, App.CurrentFile.ProgressPercent);
					model.set (iter, InputField.FILE_PROGRESS_TEXT, null);
				}

				lbl_status.label = statusLine;
				break;
		}

		return true;
	}

	private void start_cpu_usage_timer(){
		cpuUsageTimer = Timeout.add (1000, update_cpu_usage);
	}

	private bool update_cpu_usage(){
		this.title = _("CPU: ") + "%.0lf %%".printf(ProcStats.get_cpu_usage());
		return true;
	}

	private void stop_cpu_usage_timer(){
		if (cpuUsageTimer != 0){
			Source.remove(cpuUsageTimer);
			cpuUsageTimer = 0;
		}
	}

	private void update_status_all(){
		var model = (Gtk.TreeStore)treeview.model;
		MediaFile mf;
		int index = -1;
		TreeIter iter;

		bool iterExists = model.get_iter_first (out iter);
		index++;

		while (iterExists){
			mf = App.InputFiles[index];
			model.set (iter, InputField.FILE_PROGRESS, mf.ProgressPercent);
			model.set (iter, InputField.FILE_PROGRESS_TEXT, mf.ProgressText);

			iterExists = model.iter_next (ref iter);
			index++;
		}
	}

	private bool shutdown(){
		shutdown();
		return true;
	}
}

