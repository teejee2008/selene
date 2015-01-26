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
	//main toolbar
	private Gtk.Toolbar toolbar;
    private ToolButton btnAddFiles;
	private ToolButton btnRemoveFiles;
    private ToolButton btnClearFiles;
    private ToolButton btnEncoders;
    private ToolButton btnAppSettings;
    private ToolButton btnAbout;
    private ToolButton btnDonate;
    private ToolButton btnOpenOutputFolder;
    private ToolButton btnStart;
    private ToolButton btnStop;
    private ToolButton btnFinish;
    private ToolButton btnPause;
    private ToggleToolButton btnShutdown;
    private ToggleToolButton btnBackground;
    private SeparatorToolItem separator1;
    private SeparatorToolItem separator2;
    
    //preset toolbar
    private Gtk.Toolbar toolbar2;
    private ToolButton btnAddPreset;
	private ToolButton btnRemovePreset;
	private ToolButton btnBrowsePresetFolder;
	private ToolButton btnPresetInfo;

	private Box vboxMain;
	private Box vboxMain2;
	private ComboBox cmbScriptFile;
	private ComboBox cmbScriptFolder;
	private Label lblScriptFile;
	private Label lblScriptFolder;
	private Button btnEditPreset;
	private TreeView tvFiles;
	private ScrolledWindow swFiles;
	private Label lblStatus;
	private Gtk.Menu menuFile;
	private ImageMenuItem miFileInfo;
	private ImageMenuItem miFileInfoOutput;
	private ImageMenuItem miFileSkip;	
	private Gtk.MenuItem miFileCropAuto;
	private Gtk.MenuItem miFileRemove;
	private Gtk.MenuItem miFilePreview;
	private Gtk.MenuItem miFilePlaySource;
	private Gtk.MenuItem miFilePlayOutput;
	private Gtk.MenuItem miFileSeparator1;
	private Gtk.MenuItem miFileSeparator2;
	private Gtk.MenuItem miFileOpenTemp;
	private Gtk.MenuItem miFileOpenOutput;
	private Gtk.MenuItem miFileOpenLogFile;
	private TreeViewColumn colName;
	private TreeViewColumn colSize;
	private TreeViewColumn colDuration;
	private TreeViewColumn colCrop;
	private TreeViewColumn colProgress;
	private TreeViewColumn colSpacer;
	private Grid gridConfig;
	
	private Regex regexGeneric;
	private Regex regexMkvMerge;
	private Regex regexFFmpeg;
	private Regex regexLibAV;
	private Regex regexLibAV_video;
	private Regex regexLibAV_audio;
	private Regex regexX264;
	private string statusLine;
	private uint timerID = 0;
	private uint startupTimer = 0;
	private uint statusTimer = 0;
	private uint cpuUsageTimer = 0;
	private bool paused = false;
	private MediaFile lastFile;

	private const Gtk.TargetEntry[] targets = {
		{ "text/uri-list", 0, 0}
	};
	
	public MainWindow() {
		set_window_title();
        window_position = WindowPosition.CENTER;
        destroy.connect (Gtk.main_quit);
        set_default_size (550, 20);	
        icon = get_app_icon(16);

		Gtk.drag_dest_set (this,Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
		drag_data_received.connect(on_drag_data_received);
		
		Gdk.RGBA gray = Gdk.RGBA();
		gray.parse ("rgba(200,200,200,1)");

        //vboxMain
        vboxMain = new Box (Orientation.VERTICAL, 0);
        add (vboxMain);
        
        //vboxMain2
        vboxMain2 = new Box (Orientation.VERTICAL, 0);
		vboxMain2.margin_left = 6;
        vboxMain2.margin_right = 6;
        
		//toolbar
		toolbar = new Gtk.Toolbar();
		toolbar.toolbar_style = ToolbarStyle.BOTH_HORIZ;
		toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		vboxMain.pack_start (toolbar, false, false, 0);

		//btnAddFiles
		btnAddFiles = new Gtk.ToolButton.from_stock ("gtk-add");
		btnAddFiles.label = _("Add Files");
		btnAddFiles.is_important = true;
		btnAddFiles.clicked.connect (btnAddFiles_clicked);
		btnAddFiles.set_tooltip_text (_("Add file(s)"));
		toolbar.add (btnAddFiles);

		//btnRemoveFiles
		btnRemoveFiles = new Gtk.ToolButton.from_stock ("gtk-remove");
		btnRemoveFiles.is_important = true;
		btnRemoveFiles.clicked.connect (btnRemoveFiles_clicked);
		btnRemoveFiles.set_tooltip_text (_("Remove selected file(s)"));
		toolbar.add (btnRemoveFiles);
		
		//btnClearFiles
		btnClearFiles = new Gtk.ToolButton.from_stock ("gtk-clear");
		btnClearFiles.is_important = true;
		btnClearFiles.clicked.connect (btnClearFiles_clicked);
		btnClearFiles.set_tooltip_text (_("Remove all file(s)"));
		toolbar.add (btnClearFiles);
		
		//separator
		separator1 = new Gtk.SeparatorToolItem();
		toolbar.add(separator1);

		//btnStart
		btnStart = new Gtk.ToolButton.from_stock ("gtk-media-play");
		btnStart.is_important = true;
		btnStart.label = _("Start");
		btnStart.clicked.connect (start);
		btnStart.set_tooltip_text (_("Start"));
		toolbar.add (btnStart);
		
		//btnPause
		btnPause = new Gtk.ToolButton.from_stock ("gtk-media-pause");
		btnPause.is_important = true;
		btnPause.clicked.connect (btnPause_clicked);
		btnPause.set_tooltip_text (_("Pause"));
		btnPause.visible = false;
		btnPause.no_show_all = true;
		toolbar.add (btnPause);
		
		//btnStop
		btnStop = new Gtk.ToolButton.from_stock ("gtk-media-stop");
		btnStop.is_important = true;
		btnStop.clicked.connect (btnStop_clicked);
		btnStop.set_tooltip_text (_("Abort"));
		btnStop.visible = false;
		btnStop.no_show_all = true;
		toolbar.add (btnStop);
		
		//btnFinish
		btnFinish = new Gtk.ToolButton.from_stock ("gtk-ok");
		btnFinish.is_important = true;
		btnFinish.label = _("Finish");
		btnFinish.clicked.connect (() => {  convert_finish(); });
		btnFinish.set_tooltip_text (_("Finish"));
		btnFinish.visible = false;
		btnFinish.no_show_all = true;
		toolbar.add (btnFinish);
		
		//separator
		separator2 = new Gtk.SeparatorToolItem();
		separator2.set_draw (false);
		separator2.set_expand (true);
		toolbar.add (separator2);
		
		//btnAppSettings
		btnAppSettings = new Gtk.ToolButton.from_stock ("gtk-preferences");
		btnAppSettings.clicked.connect (btnAppSettings_clicked);
		btnAppSettings.set_tooltip_text (_("Application Settings"));
		toolbar.add (btnAppSettings);

		//btnEncoders
		btnEncoders = new Gtk.ToolButton.from_stock ("gtk-info");
		btnEncoders.clicked.connect (btnEncoders_clicked);
		btnEncoders.set_tooltip_text (_("Encoders"));
		toolbar.add (btnEncoders);
		
        //btn_donate
		btnDonate = new Gtk.ToolButton.from_stock ("gtk-dialog-info");
		btnDonate.is_important = false;
		btnDonate.icon_widget = get_shared_icon("donate","donate.svg",24);
		btnDonate.label = _("Donate");
		btnDonate.set_tooltip_text (_("Donate"));
        toolbar.add(btnDonate);

        btnDonate.clicked.connect(btnDonation_clicked);
        
		//btnAbout
		btnAbout = new Gtk.ToolButton.from_stock ("gtk-about");
		btnAbout.is_important = false;
		btnAbout.icon_widget = get_shared_icon("","help-info.svg",24);
		btnAbout.clicked.connect (btnAbout_clicked);
		btnAbout.set_tooltip_text (_("About"));
		toolbar.add (btnAbout);
		
		//btnShutdown
		btnShutdown = new Gtk.ToggleToolButton.from_stock ("gtk-quit");
		btnShutdown.label = _("Shutdown");
		btnShutdown.visible = false;
		btnShutdown.no_show_all = true;
		btnShutdown.is_important = true;
		btnShutdown.clicked.connect (btnShutdown_clicked);
		btnShutdown.set_tooltip_text (_("Shutdown system after completion"));
		toolbar.add (btnShutdown);
		
		//btnBackground
        btnBackground = new Gtk.ToggleToolButton.from_stock ("gtk-sort-ascending");
        btnBackground.label = _("Background");
        btnBackground.visible = false;
        btnBackground.no_show_all = true;
        btnBackground.is_important = true;
        btnBackground.clicked.connect (btnBackground_clicked);
        btnBackground.set_tooltip_text (_("Run processes with lower priority"));
        toolbar.add (btnBackground);
        
        //btnOpenOutputFolder
		btnOpenOutputFolder = new Gtk.ToolButton.from_stock ("gtk-directory");
		//btnOpenOutputFolder.is_important = true;
		btnOpenOutputFolder.label = _("Output");
		btnOpenOutputFolder.clicked.connect (btnOpenOutputFolder_click);
		btnOpenOutputFolder.set_tooltip_text (_("Open output folder"));
		btnOpenOutputFolder.visible = false;
		btnOpenOutputFolder.no_show_all = true;
		toolbar.add (btnOpenOutputFolder);
		
		//tvFiles
		tvFiles = new TreeView();
		tvFiles.get_selection().mode = SelectionMode.MULTIPLE;
		tvFiles.set_tooltip_text (_("File(s) to convert"));
		tvFiles.set_rules_hint (true);

		swFiles = new ScrolledWindow(tvFiles.get_hadjustment(), tvFiles.get_vadjustment());
		swFiles.set_shadow_type (ShadowType.ETCHED_IN);
		swFiles.add (tvFiles);
		swFiles.margin = 6;
		swFiles.set_size_request (-1, 250);

		vboxMain.pack_start (swFiles, true, true, 0);

		//colName
		colName = new TreeViewColumn();
		colName.title = _("File");
		colName.expand = true;
		CellRendererText cellName = new CellRendererText();
		cellName.ellipsize = Pango.EllipsizeMode.END;
		colName.pack_start (cellName, false);
		colName.set_attributes(cellName, "text", InputField.FILE_NAME);
		tvFiles.append_column(colName);
		
		//colSize
		colSize = new TreeViewColumn();
		colSize.title = _("Size");
		CellRendererText cellSize = new CellRendererText();
		colSize.pack_start (cellSize, false);
		colSize.set_attributes(cellSize, "text", InputField.FILE_SIZE);
		tvFiles.append_column(colSize);
		
		//colDuration
		colDuration = new TreeViewColumn();
		colDuration.title = _("Duration");
		CellRendererText cellDuration = new CellRendererText();
		colDuration.pack_start (cellDuration, false);
		colDuration.set_attributes(cellDuration, "text", InputField.FILE_DURATION);
		tvFiles.append_column(colDuration);

		//colCrop
		colCrop = new TreeViewColumn();
		colCrop.title = _("CropVideo (L:T:R:B)");
		colCrop.fixed_width = 100;
		CellRendererText cellCrop = new CellRendererText();
		cellCrop.editable = true;
		cellCrop.edited.connect (tvFiles_crop_cell_edited);
		colCrop.pack_start (cellCrop, false);
		colCrop.set_attributes(cellCrop, "text", InputField.FILE_CROPVAL);
		tvFiles.append_column(colCrop);
		
		//colProgress
		colProgress = new TreeViewColumn();
		colProgress.title = _("Status");
		colProgress.fixed_width = 120;
		CellRendererProgress2 cellProgress = new CellRendererProgress2();
		cellProgress.height = 15;
		cellProgress.width = 150;
		colProgress.pack_start (cellProgress, false);
		colProgress.set_attributes(cellProgress, "value", InputField.FILE_PROGRESS, "text", InputField.FILE_PROGRESS_TEXT);
		tvFiles.append_column(colProgress);
		
		//colSpacer
		colSpacer = new TreeViewColumn();
		colSpacer.expand = false;
		colSpacer.fixed_width = 10;
		CellRendererText cellSpacer = new CellRendererText();
		colSpacer.pack_start (cellSpacer, false);
		tvFiles.append_column(colSpacer);

		startupTimer = Timeout.add (100,() => 
		{	
			colProgress.visible = false; 
			Source.remove (startupTimer); 
			return true; 
		});

		Gtk.drag_dest_set (tvFiles,Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
        tvFiles.drag_data_received.connect(on_drag_data_received);

		// Preset tool bar --------------------------------------

        //toolbar
		toolbar2 = new Gtk.Toolbar();
		toolbar2.toolbar_style = ToolbarStyle.BOTH_HORIZ;
		//toolbar2.margin_top = 3;
		toolbar2.set_icon_size(IconSize.SMALL_TOOLBAR);
		//toolbar2.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		vboxMain.add (toolbar2);

		//btnAddPreset
		btnAddPreset = new Gtk.ToolButton.from_stock ("gtk-add");
		btnAddPreset.is_important = true;
		btnAddPreset.label = _("Add Preset");
		btnAddPreset.clicked.connect (btnAddPreset_clicked);
		btnAddPreset.set_tooltip_text (_("Add New Preset"));
		toolbar2.add (btnAddPreset);

		//btnRemovePreset
		btnRemovePreset = new Gtk.ToolButton.from_stock ("gtk-delete");
		btnRemovePreset.is_important = true;
		btnRemovePreset.clicked.connect (btnRemovePreset_clicked);
		btnRemovePreset.set_tooltip_text (_("Delete Preset"));
		toolbar2.add (btnRemovePreset);
		
		/*//btnEditPreset
		btnEditPreset = new Gtk.ToolButton.from_stock ("gtk-edit");
		btnEditPreset.is_important = true;
		btnEditPreset.clicked.connect (btnEditPreset_clicked);
		btnEditPreset.set_tooltip_text (_("Edit Preset"));
		toolbar2.add (btnEditPreset);*/
		
		//btnBrowsePresetFolder
		btnBrowsePresetFolder = new Gtk.ToolButton.from_stock ("gtk-directory");
		btnBrowsePresetFolder.is_important = true;
		btnBrowsePresetFolder.label = _("Browse");
		btnBrowsePresetFolder.clicked.connect (btnBrowsePresetFolder_clicked);
		btnBrowsePresetFolder.set_tooltip_text (_("Open Folder"));
		toolbar2.add (btnBrowsePresetFolder);
		
		/*//separator
		var separator1 = new Gtk.SeparatorToolItem();
		separator1.set_draw (false);
		separator1.set_expand (true);
		toolbar2.add (separator1);*/
		
		//btnPresetInfo
		btnPresetInfo = new Gtk.ToolButton.from_stock ("gtk-info");
		btnPresetInfo.is_important = true;
		btnPresetInfo.margin_right = 6;
		btnPresetInfo.label = _("Info");
		btnPresetInfo.clicked.connect (btnPresetInfo_clicked);
		btnPresetInfo.set_tooltip_text (_("Info"));
		toolbar2.add (btnPresetInfo);

        //Config ---------------------------------------------------
        
        vboxMain.add (vboxMain2);

        //gridConfig
        gridConfig = new Grid();
        gridConfig.set_column_spacing (6);
        gridConfig.set_row_spacing (6);
        gridConfig.visible = false;
        gridConfig.margin_top = 6;
        gridConfig.margin_bottom = 6;
        vboxMain2.add (gridConfig);

		//lblScriptFolder
		lblScriptFolder = new Gtk.Label(_("Folder"));
		lblScriptFolder.xalign = (float) 0.0;
		gridConfig.attach(lblScriptFolder,0,0,1,1);
		
        //cmbScriptFolder 
		cmbScriptFolder = new ComboBox();
		CellRendererText cellScriptFolder = new CellRendererText();
        cmbScriptFolder.pack_start( cellScriptFolder, false );
        cmbScriptFolder.set_cell_data_func (cellScriptFolder, cellScriptFolder_render);
        cmbScriptFolder.set_size_request(100,-1);
		cmbScriptFolder.set_tooltip_text (_("Folder"));
		cmbScriptFolder.changed.connect(cmbScriptFolder_changed);
		gridConfig.attach(cmbScriptFolder,1,0,1,1);
		
		//lblScriptFile
		lblScriptFile = new Gtk.Label(_("Preset"));
		lblScriptFile.xalign = (float) 0.0;
		gridConfig.attach(lblScriptFile,0,1,1,1);
		
		//cmbScriptFile
		cmbScriptFile = new ComboBox();
		cmbScriptFile.hexpand = true;
		CellRendererText cellScriptFile = new CellRendererText();
        cmbScriptFile.pack_start( cellScriptFile, false );
        cmbScriptFile.set_cell_data_func (cellScriptFile, cellScriptFile_render);
        cmbScriptFile.set_tooltip_text (_("Encoding Script or Preset File"));
        cmbScriptFile.changed.connect(cmbScriptFile_changed);
        gridConfig.attach(cmbScriptFile,1,1,1,1);
		
		//btnEditPreset
		btnEditPreset = new Button.with_label("");
		btnEditPreset.always_show_image = true;
		btnEditPreset.image = new Gtk.Image.from_file(App.SharedImagesFolder + "/video-edit.png");
		//btnEditPreset.image_position = PositionType.TOP;
		//btnEditPreset.set_size_request(64,64);
		btnEditPreset.set_tooltip_text(_("Edit Preset"));
		btnEditPreset.clicked.connect(btnEditPreset_clicked);
        gridConfig.attach(btnEditPreset,2,0,1,2);
        
		//lblStatus
		lblStatus = new Label("");
		lblStatus.ellipsize = Pango.EllipsizeMode.END;
		lblStatus.margin_top = 6;
		lblStatus.margin_bottom = 6;
		vboxMain2.add (lblStatus);
		
		statusbar_default_message();
		
		// menuFile
		menuFile = new Gtk.Menu();

		// miFileSkip
		miFileSkip = new ImageMenuItem.from_stock ("gtk-stop", null);
		miFileSkip.label = _("Skip File");
		miFileSkip.activate.connect (() => { App.stop_file(); });
		menuFile.append(miFileSkip);
		
		// miFileCropAuto
		miFileCropAuto = new Gtk.MenuItem.with_label (_("AutoCrop Video"));
		miFileCropAuto.activate.connect(miFileCropAuto_clicked);
		menuFile.append(miFileCropAuto);

		// miFilePreview
		miFilePreview = new Gtk.MenuItem.with_label (_("Preview File"));
		miFilePreview.activate.connect(miFilePreview_clicked);
		menuFile.append(miFilePreview);		
		
		// miFileRemove
		miFileRemove = new ImageMenuItem.from_stock("gtk-remove", null);
		miFileRemove.activate.connect(miFileRemove_clicked);
		menuFile.append(miFileRemove);	
		
		// miFileSeparator1
		miFileSeparator1 = new Gtk.MenuItem();
		miFileSeparator1.override_color (StateFlags.NORMAL, gray);
		menuFile.append(miFileSeparator1);
		
		// miFileOpenTemp
		miFileOpenTemp = new ImageMenuItem.from_stock("gtk-directory", null);
		miFileOpenTemp.label = _("Open Temp Folder");
		miFileOpenTemp.activate.connect(miFileOpenTemp_clicked);
		menuFile.append(miFileOpenTemp);
		
		// miFileOpenOutput
		miFileOpenOutput = new ImageMenuItem.from_stock("gtk-directory", null);
		miFileOpenOutput.label = _("Open Output Folder");
		miFileOpenOutput.activate.connect(miFileOpenOutput_clicked);
		menuFile.append(miFileOpenOutput);
		
		// miFileOpenLogFile
		miFileOpenLogFile = new ImageMenuItem.from_stock("gtk-info", null);
		miFileOpenLogFile.label = _("Open Log File");
		miFileOpenLogFile.activate.connect(miFileOpenLogFile_clicked);
		menuFile.append(miFileOpenLogFile);

		// miFileSeparator2
		miFileSeparator2 = new Gtk.MenuItem();
		miFileSeparator2.override_color (StateFlags.NORMAL, gray);
		menuFile.append(miFileSeparator2);
		
		// miFilePlaySource
		miFilePlaySource = new ImageMenuItem.from_stock("gtk-media-play", null);
		miFilePlaySource.label = _("Play File (Source)");
		miFilePlaySource.activate.connect(miFilePlaySource_clicked);
		menuFile.append(miFilePlaySource);
		
		// miFilePlayOutput
		miFilePlayOutput = new ImageMenuItem.from_stock("gtk-media-play", null);
		miFilePlayOutput.label = _("Play File (Output)");
		miFilePlayOutput.activate.connect(miFilePlayOutput_clicked);
		menuFile.append(miFilePlayOutput);
		
		// miFileInfo
		miFileInfo = new ImageMenuItem.from_stock("gtk-properties", null);
		miFileInfo.label = _("File Info (Source)");
		miFileInfo.activate.connect(miFileInfo_clicked);
		menuFile.append(miFileInfo);
		
		// miFileInfoOutput
		miFileInfoOutput = new ImageMenuItem.from_stock("gtk-properties", null);
		miFileInfoOutput.label = _("File Info (Output)");
		miFileInfoOutput.activate.connect(miFileInfoOutput_clicked);
		menuFile.append(miFileInfoOutput);
		
		menuFile.show_all();
		
        tvFiles.popup_menu.connect(() => { return menuFile_popup (menuFile, null); });
		tvFiles.button_press_event.connect ((w, event) => {
				if (event.button == 3) {
					return menuFile_popup (menuFile, event);
				}

				return false;
			});

		refresh_file_list(true);
		
		try{
			regexGeneric = new Regex("""([0-9]+[.]?[0-9]*)%""");
			regexMkvMerge = new Regex("""Progress: ([0-9]+[.]?[0-9]*)%""");
			regexFFmpeg = new Regex("""time=([0-9]+[:][0-9]+[:][0-9]+[.]?[0-9]*) """);
			regexLibAV = new Regex("""time=[ ]*([0-9]+[.]?[0-9]*)[ ]*""");
			
			//frame=   82 fps= 23 q=28.0 size=     133kB time=1.42 bitrate= 766.9kbits/s
			regexLibAV_video = new Regex("""frame=[ ]*[0-9]+[ ]*fps=[ ]*([0-9]+)[.]?[0-9]*[ ]*q=[ ]*[0-9]+[.]?[0-9]*[ ]*size=[ ]*([0-9]+)kB[ ]*time=[ ]*[0-9]+[.]?[0-9]*[ ]*bitrate=[ ]*([0-9]+)[.]?[0-9]*""");
			
			//size=    1590kB time=30.62 bitrate= 425.3kbits/s  
			regexLibAV_audio = new Regex("""size=[ ]*([0-9]+)kB[ ]*time=[ ]*[0-9]+[.]?[0-9]*[ ]*bitrate=[ ]*([0-9]+)[.]?[0-9]*""");
			
			//[53.4%] 1652/3092 frames, 24.81 fps, 302.88 kb/s, eta 0:00:58
			regexX264 = new Regex("""\[[0-9]+[.]?[0-9]*%\][ \t]*[0-9]+/[0-9]+[ \t]*frames,[ \t]*([0-9]+)[.]?[0-9]*[ \t]*fps,[ \t]*([0-9]+)[.]?[0-9]*[ \t]*kb/s,[ \t]*eta ([0-9:]+)""");
		}
		catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
		}
		
        //populate and select script
        populate_script_folders();
		select_script();
	}
	
	public void set_window_title(){
		title = AppName + " v" + AppVersion;// + " by " + AppAuthor + " (" + "teejeetech.blogspot.in" + ")";
	}
	
	// script dropdown handlers -----------------------
	
	private void populate_script_folders(){
		TreeStore model = new TreeStore(2, typeof(string), typeof(string));
		cmbScriptFolder.set_model(model);
		TreeIter iter0;

		/*model.append (out iter0, null);
		model.set (iter0, 0, App.ScriptsFolder_Official, 1, "Official Scripts");
		iter_append_children (model, iter0, App.ScriptsFolder_Official);
		
		model.append (out iter0, null);
		model.set (iter0, 0, App.PresetsFolder_Official,1, "Official Presets");
		iter_append_children (model, iter0, App.PresetsFolder_Official);
		*/
		
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
			var enumerator = dir.enumerate_children ("standard::*", 0);
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
	
	private void cmbScriptFolder_changed(){
		//create empty model
		ListStore model = new ListStore(2, typeof(ScriptFile), typeof(string));
		cmbScriptFile.set_model(model);
		
		string path = gtk_combobox_get_value(cmbScriptFolder,0,"");
		
		try
		{
			var dir = File.parse_name (path);
	        var enumerator = dir.enumerate_children ("standard::*", 0);
			Gee.ArrayList<string> files = new Gee.ArrayList<string>();
			
	        FileInfo file;
	        while ((file = enumerator.next_file()) != null) {
				files.add(dir.resolve_relative_path(file.get_name()).get_path());
	        } 
	        files.sort_with_data((a,b) => { return strcmp((string)a, (string)b); });
	        
	        foreach(string filePath in files){
		        string fileName = File.new_for_path(filePath).get_basename();
		        
		        if (file_exists(filePath)){
					ScriptFile sh = new ScriptFile(filePath);
					if (sh.Extension == ".sh" || sh.Extension == ".json") {
						TreeIter iter;
						model.append(out iter);
						model.set(iter, 0, sh, 1, fileName);
						
						if (App.SelectedScript != null && App.SelectedScript.Path == sh.Path) {
							cmbScriptFile.set_active_iter(iter);
						}
					}
				}
			}

	        if (cmbScriptFile.active < 0) {
				cmbScriptFile.set_active(0);
			}
        }
        catch(Error e){
	        log_error (e.message);
	    }
	}
	
	private void cmbScriptFile_changed(){
		if ((cmbScriptFile == null)||(cmbScriptFile.model == null)||(cmbScriptFile.active < 0)){ return; }
		
		ScriptFile sh;
		TreeIter iter;
		cmbScriptFile.get_active_iter(out iter);
		cmbScriptFile.model.get (iter, 0, out sh, -1);
		
		App.SelectedScript = sh;
	}
	
	private bool select_script(){
		if ((App.SelectedScript == null)||(file_exists(App.SelectedScript.Path) == false)){
			cmbScriptFolder.set_active(2);
			cmbScriptFile.set_active(0);
			return false;
		}
		
		string filePath = App.SelectedScript.Path;
		
		string dirPath = GLib.Path.get_dirname(filePath);
		bool retVal = false;
		TreeIter iter;

		//select folder
		TreeStore model = (TreeStore) cmbScriptFolder.model;
		for (bool next = model.get_iter_first (out iter); next; next = model.iter_next (ref iter)) {
			string path;
			model.get (iter, 0, out path);
			if (path == dirPath){
				cmbScriptFolder.set_active_iter(iter);
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
			cmbScriptFolder.set_active(-1); 
			
			//add the selected file
			ListStore model1 = new ListStore(2, typeof(ScriptFile), typeof(string));
			cmbScriptFile.set_model(model1);
			ScriptFile sh = new ScriptFile(filePath);
			model1.append(out iter);
			model1.set(iter, 0, sh, 1, sh.Title);
			
			//select it
			cmbScriptFile.set_active(0); 
		}

		//select file
		ListStore model1 = (ListStore) cmbScriptFile.model;
		for (bool next = model1.get_iter_first (out iter); next; next = model1.iter_next (ref iter)) {
			ScriptFile sh = new ScriptFile(filePath);
			model1.get (iter, 0, out sh);
			if (sh.Path == filePath){
				cmbScriptFile.set_active_iter(iter);
				retVal = true;
				break;
			}
		}
		
		return retVal;
	}
	
	private bool select_script_recurse_children (string filePath, TreeIter iter0){
		TreeStore model = (TreeStore) cmbScriptFolder.model;
		string dirPath = GLib.Path.get_dirname(filePath);
		bool retVal = false;
		
		TreeIter iter1;
		int index = 0;
		
		for (bool next = model.iter_children (out iter1, iter0); next; next = model.iter_nth_child (out iter1, iter0, index)) {
			
			string path;
			model.get (iter1, 0, out path);
			
			if (path == dirPath){
				cmbScriptFolder.set_active_iter(iter1);
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
	
	private void cellScriptFolder_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		string name;
		model.get (iter, 1, out name, -1);
		(cell as Gtk.CellRendererText).text = name;
	}
	
	private void btnBrowsePresetFolder_clicked(){
		string path;
		TreeModel model = (TreeModel) cmbScriptFolder.model;
		TreeIter iter;
		cmbScriptFolder.get_active_iter(out iter);
		model.get (iter, 0, out path, -1);
		exo_open_folder (path); 
	}
	
	private void miFileOpenLogFile_clicked(){
		TreeSelection selection = tvFiles.get_selection();
		
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
		var window = new EncoderConfigWindow();
		window.set_transient_for(this);
	    window.Folder = gtk_combobox_get_value(cmbScriptFolder,0,"");
	    window.Name = "New Preset";
	    //window.CreateNew = true;
	    window.show_all();
	    window.run();

	    //App.SelectedScript will be set on click of 'Save' button
	    cmbScriptFolder_changed();
	}
	
	private void preset_edit(){
		ScriptFile sh;
		TreeIter iter;
		cmbScriptFile.get_active_iter(out iter);
		cmbScriptFile.model.get (iter, 0, out sh, -1);
		
		if (sh.Extension == ".json") {
			var window = new EncoderConfigWindow();
			window.set_transient_for(this);
			window.Folder = sh.Folder;
			window.Name = sh.Title;
			window.show_all();
			window.load_script();
			window.run();
			cmbScriptFolder_changed();
		}
	}
	
	private void script_create(){
		string folder = gtk_combobox_get_value(cmbScriptFolder,0,"");
		
		int k = 0;
		string new_script = "%s/new_script.sh".printf(folder);
		while (file_exists(new_script)){
			new_script = "%s/new_script_%d.sh".printf(folder,++k);
		}
		
		write_file(new_script,"");
		exo_open_textfile(new_script); 
		
		App.SelectedScript = new ScriptFile(new_script);
		cmbScriptFolder_changed();
	}
	
	private void script_edit(){
		ScriptFile sh;
		TreeIter iter;
		cmbScriptFile.get_active_iter(out iter);
		cmbScriptFile.model.get (iter, 0, out sh, -1);

		if (sh.Extension == ".sh") {
			exo_open_textfile(sh.Path); 
		}
	}
	
	private void btnAddPreset_clicked(){
		TreeIter iter;
		string folderName;
		cmbScriptFolder.get_active_iter(out iter);
		cmbScriptFolder.model.get (iter, 1, out folderName, -1);

		if (folderName.has_prefix("scripts")){
			script_create();
		}
		else if (folderName.has_prefix("presets")){
			preset_create();
		}
	}

	private void btnRemovePreset_clicked(){
		if ((cmbScriptFile.model != null)&&(cmbScriptFile.active > -1)) {
			ScriptFile sh;
			TreeIter iter;
			cmbScriptFile.get_active_iter(out iter);
			cmbScriptFile.model.get (iter, 0, out sh, -1);
			
			file_delete(sh.Path);
			cmbScriptFolder_changed();
			
			statusbar_show_message (_("Preset deleted") + ": " + sh.Name + "", true, true);
		}
	}
	
	private void btnEditPreset_clicked(){
		if ((cmbScriptFile.model == null)||(cmbScriptFile.active == -1)) {
			TreeIter iter;
			string folderName;
			cmbScriptFolder.get_active_iter(out iter);
			cmbScriptFolder.model.get (iter, 1, out folderName, -1);
			
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
			cmbScriptFile.get_active_iter(out iter);
			cmbScriptFile.model.get (iter, 0, out sh, -1);

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

	private void btnPresetInfo_clicked(){
		string msg = """Selene supports 2 types of presets:

1) JSON Presets

Ø These are files with a ".json" extension.

Ø Files are present in $HOME/.config/selene/presets.

Ø Clicking the "Edit" button on the toolbar will display a GUI for
configuring the preset file.

2) Bash Scripts

Ø These are bash scripts with a ".sh" extension.

Ø Files are present in $HOME/.config/selene/scripts.

Ø Bash scripts can be used for converting files using any command line
utility (even those tools which are not directly supported by Selene)

Ø These files have to be edited manually. Clicking the "Edit" button
on the toolbar will open the file in a text editor.
""";

		var dlg = new Gtk.MessageDialog(null,Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, msg);
		dlg.set_title(_("Info"));
		dlg.set_modal(true);
		dlg.set_transient_for(this);
		dlg.run();
		dlg.destroy();
	}

	// statusbar -------------------
	
    private void statusbar_show_message (string message, bool is_error = false, bool timeout = true){
		Gdk.RGBA red = Gdk.RGBA();
		Gdk.RGBA white = Gdk.RGBA();
		red.parse ("rgba(255,0,0,1)");
		white.parse ("rgba(0,0,0,1)");
		
		if (is_error)
			lblStatus.override_color (StateFlags.NORMAL, red);
		else
			lblStatus.override_color (StateFlags.NORMAL, null);
		
		lblStatus.label = message;
		
		if (timeout)
			statusbar_set_timeout();
	}
	
    private void statusbar_set_timeout(){
		//Source.remove (statusTimer);
		statusTimer = Timeout.add (3000, statusbar_clear);
	}
    
    private bool statusbar_clear(){
		//Source.remove (statusTimer);
		lblStatus.label = "";
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
				statusbar_show_message(_("Converting: '%s'").printf (App.CurrentFile.Path), false, false);
				break;
		}
	}
	
	// file list and context menu -------------------------
	
	private void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) {
        foreach(string uri in data.get_uris()){
			string file = uri.replace("file://","").replace("file:/","");
			file = Uri.unescape_string (file);
			bool valid = App.add_file (file);
			if (!valid){
				statusbar_show_message (_("Unknown format: '%s'").printf (file), true, true);
			}
			else {
				statusbar_show_message (_("File added: '%s'").printf (file));
			}
		}
        
        refresh_file_list(true);
		
        Gtk.drag_finish (drag_context, true, false, time);
    }

    private bool menuFile_popup (Gtk.Menu popup, Gdk.EventButton? event) {
		TreeSelection selection = tvFiles.get_selection();
		int index = -1;
		
		if (selection.count_selected_rows() == 0){
			return true;
		}
		
		if (selection.count_selected_rows() == 1){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			index = int.parse (path.to_string());
		}

		switch(App.Status){
			case AppStatus.NOTSTARTED:
				miFileSkip.visible = false;
				miFileOpenTemp.visible = false;
				miFileOpenOutput.visible = false;
				miFileOpenLogFile.visible = false;
				
				miFileInfo.visible = true;
				miFileInfoOutput.visible = false;
				miFilePreview.visible = true;
				miFilePlaySource.visible = true;
				miFilePlayOutput.visible = false;
				miFileCropAuto.visible = true;
				miFileRemove.visible = true;
				miFileSeparator1.visible = true;
				miFileSeparator2.visible = false;
				
				miFileInfo.sensitive = (selection.count_selected_rows() == 1);
				miFilePreview.sensitive = (selection.count_selected_rows() == 1);
				miFilePlaySource.sensitive = (selection.count_selected_rows() == 1);
				miFileCropAuto.sensitive = (selection.count_selected_rows() > 0);
				miFileRemove.sensitive = (selection.count_selected_rows() > 0);
				break;
			
			case AppStatus.RUNNING:
				
				miFileSkip.visible = true;
				miFileSeparator1.visible = true;
				miFileSeparator2.visible = false;
				miFileOpenTemp.visible = true;
				miFileOpenOutput.visible = true;
				miFileOpenLogFile.visible = false;
				
				if (selection.count_selected_rows() == 1){
					if (App.InputFiles[index].Status == FileStatus.RUNNING){
						miFileSkip.sensitive = true;
					}
					else{
						miFileSkip.sensitive = false;
					}
					if (dir_exists(App.InputFiles[index].TempDirectory)){
						miFileOpenTemp.sensitive = true;
					}
					else{
						miFileOpenTemp.sensitive = false;
					}
					miFileOpenOutput.sensitive = false;
				}
				else{
					miFileSkip.sensitive = false;
					miFileOpenTemp.sensitive = false;
					miFileOpenOutput.sensitive = false;
				}

				miFileInfo.visible = false;
				miFileInfoOutput.visible = false;
				miFilePreview.visible = false;
				miFilePlaySource.visible = false;
				miFilePlayOutput.visible = false;
				miFileCropAuto.visible = false;
				miFileRemove.visible = false;
				break;
			
			case AppStatus.IDLE:
			
				miFileOpenTemp.visible = true;
				miFileOpenOutput.visible = true;
				miFileOpenLogFile.visible = true;
				
				if (index != -1){
					miFileOpenTemp.sensitive = true;
					miFileOpenOutput.sensitive = true;
				}
				else{
					miFileOpenTemp.sensitive = false;
					miFileOpenOutput.sensitive = false;
				}
				
				miFileSkip.visible = false;
				miFileInfo.visible = true;
				miFileInfoOutput.visible = true;
				miFilePlaySource.visible = true;
				miFilePlayOutput.visible = true;
				miFilePreview.visible = false;
				miFileCropAuto.visible = false;
				miFileRemove.visible = false;
				miFileSeparator1.visible = false;
				miFileSeparator2.visible = true;
				
				if (selection.count_selected_rows() == 1){
					string outpath = App.InputFiles[index].OutputFilePath;
					if (outpath != null && outpath.length > 0 && file_exists(outpath)){
						miFileInfoOutput.sensitive = true;
						miFilePlayOutput.sensitive = true;
					}
				}
				else{
					miFileInfoOutput.sensitive = false;
					miFilePlayOutput.sensitive = false;
				}

				break;
		}
		
		if (event != null) {
			menuFile.popup (null, null, null, event.button, event.time);
		} else {
			menuFile.popup (null, null, null, 0, Gtk.get_current_event_time());
		}
		return true;
	}

    private void miFileInfo_clicked() {
		TreeSelection selection = tvFiles.get_selection();
		
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
    
    private void miFileInfoOutput_clicked() {
		TreeSelection selection = tvFiles.get_selection();
		
		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());
			
			MediaFile mf = App.InputFiles[index];

			if (file_exists(mf.OutputFilePath)){
				MediaFile mfOutput = new MediaFile(mf.OutputFilePath);
				var window = new FileInfoWindow(mfOutput);
				window.set_transient_for(this);
				window.show_all();
				window.run();
			}
		}	
	}
	
    private void miFileCropAuto_clicked() {
		TreeSelection selection = tvFiles.get_selection();
		if (selection.count_selected_rows() == 0){ return; }
			
		set_busy (true,this);
		
		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);
		
		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string());
			MediaFile file = App.InputFiles[index];
			
			if (file.crop_detect()){
				((ListStore)tvFiles.model).set (iter, InputField.FILE_CROPVAL, file.crop_values_info());
			}
			else{
				((ListStore)tvFiles.model).set (iter, InputField.FILE_CROPVAL, _("N/A"));
			}	
			
			do_events();
		}

		set_busy (false,this);
    }
    
    private void miFileRemove_clicked() {
		btnRemoveFiles_clicked();
    }
    
    private void miFileOpenTemp_clicked() {
		TreeSelection selection = tvFiles.get_selection();
		if (selection.count_selected_rows() == 0){ return; }
		
		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);
		
		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];
			exo_open_folder (mf.TempDirectory);
		}
    }
    
    private void miFileOpenOutput_clicked() {
		TreeSelection selection = tvFiles.get_selection();
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
				exo_open_folder (mf.Location);
			} else{
				exo_open_folder (App.OutputDirectory);
			}
		}
    }
    
    private void btnOpenOutputFolder_click(){
		if (App.OutputDirectory.length > 0 && dir_exists(App.OutputDirectory)){
			exo_open_folder (App.OutputDirectory);
		}
	}
	
	private void set_busy (bool busy, Gtk.Window win) {
		Gdk.Cursor? cursor = null;

		if (busy){
			cursor = new Gdk.Cursor(Gdk.CursorType.WATCH);
		}
		else{
			cursor = new Gdk.Cursor(Gdk.CursorType.ARROW);
		}
		
		var window = win.get_window();
		
		if (window != null) {
			window.set_cursor (cursor);
		}
		
		do_events();
	}
    
    private void do_events(){
		while(Gtk.events_pending())
			Gtk.main_iteration();
	}
	
    private void miFilePreview_clicked() {
		TreeSelection selection = tvFiles.get_selection();
		
		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];
			
			mf.preview_output();
		}
	}
	
    private void miFilePlayOutput_clicked() {
		TreeSelection selection = tvFiles.get_selection();
		
		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];
			
			mf.play_output();
		}
    }
    
    private void miFilePlaySource_clicked() {
		TreeSelection selection = tvFiles.get_selection();
		
		if (selection.count_selected_rows() > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string());
			MediaFile mf = App.InputFiles[index];
			
			mf.play_source();
		}
    }

	private void refresh_file_list (bool refresh_model){
		ListStore inputStore = new ListStore (9, typeof(MediaFile), typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (int), typeof (string));
		
		TreeIter iter;
		foreach(MediaFile mFile in App.InputFiles) {
			inputStore.append (out iter);
			inputStore.set (iter, InputField.FILE_REF, mFile);
			inputStore.set (iter, InputField.FILE_PATH, mFile.Path);
	    	inputStore.set (iter, InputField.FILE_NAME, mFile.Name);
	    	inputStore.set (iter, InputField.FILE_SIZE, format_file_size(mFile.Size));
	    	inputStore.set (iter, InputField.FILE_DURATION, format_duration(mFile.Duration));
	    	inputStore.set (iter, InputField.FILE_STATUS, "gtk-media-pause");
	    	inputStore.set (iter, InputField.FILE_CROPVAL, mFile.crop_values_info());
	    	inputStore.set (iter, InputField.FILE_PROGRESS, mFile.ProgressPercent);
	    	inputStore.set (iter, InputField.FILE_PROGRESS_TEXT, mFile.ProgressText);
		}
			
		tvFiles.set_model (inputStore);
		
		tvFiles.columns_autosize();
	}
	
	public void tvFiles_crop_cell_edited (string path, string new_text) {
		int index = int.parse (path.to_string());
		MediaFile mf = App.InputFiles[index];
		
		if (new_text == null || new_text.length == 0){
			mf.crop_reset();
		}
		else{
			string[ ] arr = new_text.replace ("  "," ").split (":");
			if (arr.length == 4){
				mf.CropL = int.parse(arr[0]);
				mf.CropT = int.parse(arr[1]);
				mf.CropR = int.parse(arr[2]);
				mf.CropB = int.parse(arr[3]);
				mf.CropW = mf.SourceWidth  - mf.CropL - mf.CropR;
				mf.CropH = mf.SourceHeight - mf.CropT - mf.CropB;
			}
		}
		
		ListStore model = (ListStore) tvFiles.model;
		TreeIter iter;
		model.get_iter (out iter, new TreePath.from_string (path));
		model.set (iter, InputField.FILE_CROPVAL, mf.crop_values_info());
	}
	
	// toolbar --------------------------------
	
	private void btnAddFiles_clicked(){
		var dlgAddFiles = new Gtk.FileChooserDialog(_("Add File(s)"), this, Gtk.FileChooserAction.OPEN,
							"gtk-cancel", Gtk.ResponseType.CANCEL,
							"gtk-open", Gtk.ResponseType.ACCEPT);
		dlgAddFiles.local_only = true;
 		dlgAddFiles.set_modal (true);
 		dlgAddFiles.set_select_multiple (true);
		if (App.InputDirectory.length > 0) {
			dlgAddFiles.set_current_folder(App.InputDirectory);
		}
		
 		if (dlgAddFiles.run() == Gtk.ResponseType.ACCEPT){
			
			set_busy(true,dlgAddFiles);

	 		foreach (string file in dlgAddFiles.get_filenames()){
				bool added = App.add_file (file);
				if (added == false){
					statusbar_show_message (_("Format not supported:") + "'" + file + "'", true, true);
				}
			}
			
			App.InputDirectory = dlgAddFiles.get_current_folder();
	 	}

	 	refresh_file_list(true);
	 	
	 	dlgAddFiles.destroy(); //resets cursor
	}
	
	private void btnRemoveFiles_clicked(){
		Gee.ArrayList<MediaFile> list = new Gee.ArrayList<MediaFile>();
		TreeSelection sel = tvFiles.get_selection();
		
		TreeIter iter;
		bool iterExists = tvFiles.model.get_iter_first (out iter);
		while (iterExists) { 
			if (sel.iter_is_selected (iter)){
				MediaFile mf;
				tvFiles.model.get (iter, InputField.FILE_REF, out mf, -1);
				list.add(mf);
			}
			iterExists = tvFiles.model.iter_next (ref iter);
		}
		
		App.remove_files(list);
		refresh_file_list(true);
	}
	
	private void btnClearFiles_clicked(){
		App.remove_all();
		refresh_file_list(true);
	}
	
	private void btnAbout_clicked(){
		var dialog = new AboutWindow();
		dialog.set_transient_for (this);

		dialog.authors = { 
			"Tony George:teejeetech@gmail.com" 
		};
		
		dialog.translators = {
			"abuyop (Malay):launchpad.net/~abuyop",
			"B. W. Knight (Korean):launchpad.net/~kbd0651",
			"Felix Moreno (Spanish):launchpad.net/~felix-justdust"
		}; 
		
		dialog.documenters = null; 
		dialog.artists = null;
		dialog.donations = null;

		dialog.program_name = AppName;
		dialog.comments = _("An audio-video converter for Linux");
		dialog.copyright = "Copyright © 2014 Tony George (%s)".printf(AppAuthorEmail);
		dialog.version = AppVersion;
		dialog.logo = get_app_icon(128);

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.website = "http://teejeetech.in";
		dialog.website_label = "http://teejeetech.blogspot.in";

		dialog.initialize();
		dialog.show_all();
	}
	
	public void btnDonation_clicked(){
		var dialog = new DonationWindow();
		dialog.set_transient_for(this);
		dialog.show_all();
		dialog.run();
		dialog.destroy();
	}
	
	private void btnEncoders_clicked(){
	    var dialog = new EncoderStatusWindow();
	    dialog.set_transient_for(this);
	    dialog.show_all();
	    dialog.run();
	    dialog.destroy();
	}
	
	private void btnAppSettings_clicked(){
	    var window = new AppConfigWindow();
	    window.set_transient_for(this);
	    window.show_all();
	    window.run();
	}
	
	private void btnShutdown_clicked(){
		App.Shutdown = btnShutdown.active;
		
		if (App.Shutdown){
			log_msg (_("Shutdown Enabled") + "\n");
		}
		else{
			log_msg (_("Shutdown Disabled") + "\n");
		}
	}
	
	private void btnBackground_clicked(){
		App.BackgroundMode = btnBackground.active;
		App.set_priority();
	}
	
	private void btnPause_clicked(){
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
				btnPause.label = _("Resume");
				btnPause.stock_id = "gtk-media-play";
				btnPause.set_tooltip_text (_("Resume"));
				statusbar_default_message();
				break; 
			case AppStatus.RUNNING:
				btnPause.label = _("Pause");
				btnPause.stock_id = "gtk-media-pause";
				btnPause.set_tooltip_text (_("Pause"));
				statusbar_default_message();
				break; 
		}
		
		update_status_all();
	}
	
	private void btnStop_clicked(){
		App.stop_batch();
		update_status_all(); 
	}
	
	// encoding ----------------------------------
	
	public void start(){
		if (App.InputFiles.size == 0){
			string msg = _("Input queue is empty!\nPlease add some files.\n");
			var dlg = new Gtk.MessageDialog(null,Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, msg);
			dlg.set_title(_("Queue is Empty"));
			dlg.set_modal(true);
			dlg.set_transient_for(this);
			dlg.run();
			dlg.destroy();
			
			return;
		}	

		
		ScriptFile sh;
		TreeIter iter;
		cmbScriptFile.get_active_iter(out iter);
		cmbScriptFile.model.get (iter, 0, out sh, -1);
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
	
	public void convert_prepare(){
		toolbar2.visible = false;
		gridConfig.visible = false;
		btnShutdown.active = App.Shutdown;
		
		btnShutdown.visible = App.AdminMode;
		btnBackground.visible = App.AdminMode;
        btnBackground.active = App.BackgroundMode;
        btnOpenOutputFolder.visible = dir_exists(App.OutputDirectory);
		
		btnStart.visible = false;
		btnAddFiles.visible = true;
		btnRemoveFiles.visible = false;
		btnClearFiles.visible = false;
		btnAppSettings.visible = false;
		btnEncoders.visible = false;
		btnDonate.visible = false;
		btnAbout.visible = false;
		
		btnShutdown.visible = App.AdminMode;
        btnShutdown.active = App.Shutdown;
        
		btnPause.visible = true;
		btnStop.visible = true;
		btnFinish.visible = false;
				
		paused = false;
		btnPause.stock_id = "gtk-media-pause";
		
		colCrop.visible = false;
		colProgress.visible = true;
		
		start_cpu_usage_timer();
	} 
	
	public void convert_finish(){
		toolbar2.visible = true;
		gridConfig.visible = true;

		colCrop.visible = true;
		colProgress.visible = false;
		
		btnStart.visible = true;
		btnAddFiles.visible = true;
		btnRemoveFiles.visible = true;
		btnClearFiles.visible = true;
		btnAppSettings.visible = true;
		btnEncoders.visible = true;
		btnDonate.visible = true;
		btnAbout.visible = true;
		
		btnShutdown.visible = false;
		btnBackground.visible = false;
		btnOpenOutputFolder.visible = false;
		
		btnPause.visible = false;
		btnStop.visible = false;
		btnFinish.visible = false;
		separator1.visible = true;

		App.convert_finish();
		
		statusbar_default_message();
	} 

	public bool update_status(){
		TreeIter iter;
		ListStore model = (ListStore)tvFiles.model;

		switch (App.Status) {
			case AppStatus.PAUSED:
				/*if (btnPause.active == false){
					btnPause.active = true;
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
				btnShutdown.visible = false;
				btnBackground.visible = false;
				btnStart.visible = false;
				btnPause.visible = false;
				btnStop.visible = false;
				btnAddFiles.visible = false;
				separator1.visible = false;
				btnFinish.visible = true;
				
				// update statusbar message
				statusbar_default_message();
				
				//stop cpu usage display
				stop_cpu_usage_timer();
				set_window_title();
		
				break;

			case AppStatus.RUNNING:
				statusLine = App.StatusLine;
				if(statusLine == null){ return false; }
				
				/*if (btnPause.active){
					btnPause.active = false;
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

				lblStatus.label = statusLine;
				break;
		}

		return true;
	}
	
	public void start_cpu_usage_timer(){
		cpuUsageTimer = Timeout.add (1000, update_cpu_usage);
	}

	private bool update_cpu_usage(){	
		this.title = _("CPU: ") + "%.2lf %%".printf(ProcStats.get_cpu_usage());
		return true;
	}
	
	public void stop_cpu_usage_timer(){
		if (cpuUsageTimer != 0){
			Source.remove(cpuUsageTimer);
			cpuUsageTimer = 0;
		}
	}
	
	public void update_status_all(){
		ListStore model = (ListStore)tvFiles.model;
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
	
	public bool shutdown(){
		shutdown();
		return true;
	}
}

public enum InputField{
	FILE_REF,
	FILE_PATH,
	FILE_NAME,
	FILE_SIZE,
	FILE_DURATION,
	FILE_STATUS,
	FILE_CROPVAL,
	FILE_PROGRESS,
	FILE_PROGRESS_TEXT
}
