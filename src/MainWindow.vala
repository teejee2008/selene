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

public class MainWindow : Gtk.Window
{
	private ToolButton btnStart;
    private ToolButton btnStop;
    private ToolButton btnFinish;
    
    private ToolButton btnPause;
    private ToggleToolButton btnShutdown;
    private ToggleToolButton btnBackground;
    
    private ToolButton btnAddFiles;
	private ToolButton btnRemoveFiles;
    private ToolButton btnClearFiles;
    private ToolButton btnAppSettings;
    private ToolButton btnAbout;
    
    private Button btnOpenScriptFolder;
	private Button btnPresetNew;
	private Button btnPresetEdit;
	
	private Box vboxMain;
	private Box vboxMain2;
	private Box hboxScript;
	private Box hboxProgress;
	private ComboBox cmbScriptFile;
	private ComboBox cmbScriptFolder;
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
	private Gtk.MenuItem miFileSeparator1;
	private Gtk.MenuItem miFileSeparator2;
	private Gtk.MenuItem miFileOpenTemp;
	private Gtk.MenuItem miFileOpenOutput;
	private TreeViewColumn colName;
	private TreeViewColumn colSize;
	private TreeViewColumn colDuration;
	private TreeViewColumn colCrop;
	private TreeViewColumn colProgress;
	private TreeViewColumn colSpacer;

	private Regex regexGeneric;
	private Regex regexMkvMerge;
	private Regex regexFFmpeg;
	private Regex regexLibAV;
	private Regex regexLibAV_video;
	private Regex regexLibAV_audio;
	private Regex regexX264;
	private string statusLine;
	private uint timerID;
	private uint startupTimer;
	private uint statusTimer;
	private bool paused = false;
	private MediaFile lastFile;

	private const Gtk.TargetEntry[] targets = {
		{ "text/uri-list", 0, 0}
	};
		
	public MainWindow () 
	{
		this.title = AppName + " v" + AppVersion;
        this.window_position = WindowPosition.CENTER;
        this.destroy.connect (Gtk.main_quit);
        set_default_size (550, 20);	
         
		Gtk.drag_dest_set (this,Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
		this.drag_data_received.connect(this.on_drag_data_received);
		
		Gdk.RGBA gray = Gdk.RGBA ();
		//Gdk.RGBA white = Gdk.RGBA ();
		gray.parse ("rgba(200,200,200,1)");
		//white.parse ("rgba(0,0,0,1)");

        //vboxMain
        vboxMain = new Box (Orientation.VERTICAL, 0);
        add (vboxMain);
        
        //vboxMain2
        vboxMain2 = new Box (Orientation.VERTICAL, 0);
		vboxMain2.margin_left = 6;
        vboxMain2.margin_right = 6;
        
		//toolbar
		Gtk.Toolbar toolbar = new Gtk.Toolbar ();
		toolbar.toolbar_style = ToolbarStyle.BOTH_HORIZ;
		toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		vboxMain.pack_start (toolbar, false, false, 0);

		//btnAddFiles
		btnAddFiles = new Gtk.ToolButton.from_stock (Gtk.Stock.ADD);
		btnAddFiles.is_important = true;
		btnAddFiles.clicked.connect (btnAddFiles_clicked);
		btnAddFiles.set_tooltip_text ("Add file(s)");
		toolbar.add (btnAddFiles);

		//btnRemoveFiles
		btnRemoveFiles = new Gtk.ToolButton.from_stock (Gtk.Stock.REMOVE);
		btnRemoveFiles.label = "";
		btnRemoveFiles.clicked.connect (btnRemoveFiles_clicked);
		btnRemoveFiles.set_tooltip_text ("Remove selected file(s)");
		toolbar.add (btnRemoveFiles);
		
		//btnClearFiles
		btnClearFiles = new Gtk.ToolButton.from_stock (Gtk.Stock.CLEAR);
		btnClearFiles.label = "";
		btnClearFiles.clicked.connect (btnClearFiles_clicked);
		btnClearFiles.set_tooltip_text ("Remove all file(s)");
		toolbar.add (btnClearFiles);
		
		//separator
		toolbar.add (new Gtk.SeparatorToolItem());
		
		//btnStart
		btnStart = new Gtk.ToolButton.from_stock (Gtk.Stock.MEDIA_PLAY);
		btnStart.is_important = true;
		btnStart.label = "Start";
		btnStart.clicked.connect (start);
		btnStart.set_tooltip_text ("Start");
		toolbar.add (btnStart);
		
		//btnPause
		btnPause = new Gtk.ToolButton.from_stock (Gtk.Stock.MEDIA_PAUSE);
		btnPause.is_important = true;
		btnPause.clicked.connect (btnPause_clicked);
		btnPause.set_tooltip_text ("Pause");
		btnPause.visible = false;
		btnPause.no_show_all = true;
		toolbar.add (btnPause);
		
		//btnStop
		btnStop = new Gtk.ToolButton.from_stock (Gtk.Stock.MEDIA_STOP);
		btnStop.is_important = true;
		btnStop.clicked.connect (btnStop_clicked);
		btnStop.set_tooltip_text ("Abort");
		btnStop.visible = false;
		btnStop.no_show_all = true;
		toolbar.add (btnStop);
		
		//btnFinish
		btnFinish = new Gtk.ToolButton.from_stock (Gtk.Stock.OK);
		btnFinish.is_important = true;
		btnFinish.label = "Finish";
		btnFinish.clicked.connect (() => {  convert_finish (); });
		btnFinish.set_tooltip_text ("Finish");
		btnFinish.visible = false;
		btnFinish.no_show_all = true;
		toolbar.add (btnFinish);
		
		//separator
		var separator = new Gtk.SeparatorToolItem();
		separator.set_draw (false);
		separator.set_expand (true);
		toolbar.add (separator);

		//btnAppSettings
		btnAppSettings = new Gtk.ToolButton.from_stock (Gtk.Stock.PREFERENCES);
		btnAppSettings.label = "";
		btnAppSettings.clicked.connect (btnAppSettings_clicked);
		btnAppSettings.set_tooltip_text ("Application Settings");
		toolbar.add (btnAppSettings);
		
		//btnAbout
		btnAbout = new Gtk.ToolButton.from_stock (Gtk.Stock.ABOUT);
		btnAbout.label = "";
		btnAbout.clicked.connect (btnAbout_clicked);
		btnAbout.set_tooltip_text ("About");
		toolbar.add (btnAbout);
		
		//btnShutdown
		btnShutdown = new Gtk.ToggleToolButton.from_stock (Gtk.Stock.QUIT);
		btnShutdown.label = "Shutdown";
		btnShutdown.visible = false;
		btnShutdown.no_show_all = true;
		btnShutdown.is_important = true;
		btnShutdown.clicked.connect (btnShutdown_clicked);
		btnShutdown.set_tooltip_text ("Shutdown system after completion");
		toolbar.add (btnShutdown);
		
		//btnBackground
        btnBackground = new Gtk.ToggleToolButton.from_stock (Gtk.Stock.SORT_ASCENDING);
        btnBackground.label = "Background";
        btnBackground.visible = false;
        btnBackground.no_show_all = true;
        btnBackground.is_important = true;
        btnBackground.clicked.connect (btnBackground_clicked);
        btnBackground.set_tooltip_text ("Run processes with lower priority");
        toolbar.add (btnBackground);
        
		//tvFiles
		tvFiles = new TreeView();
		tvFiles.get_selection().mode = SelectionMode.MULTIPLE;
		tvFiles.set_tooltip_text ("File(s) to convert");
		tvFiles.set_rules_hint (true);

		swFiles = new ScrolledWindow(tvFiles.get_hadjustment (), tvFiles.get_vadjustment ());
		swFiles.set_shadow_type (ShadowType.ETCHED_IN);
		swFiles.add (tvFiles);
		swFiles.set_size_request (-1, 250);

		vboxMain.pack_start (swFiles, true, true, 0);

		//colName
		colName = new TreeViewColumn();
		colName.title = "File";
		colName.expand = true;
		CellRendererText cellName = new CellRendererText ();
		cellName.ellipsize = Pango.EllipsizeMode.END;
		colName.pack_start (cellName, false);
		colName.set_attributes(cellName, "text", InputField.FILE_NAME);
		tvFiles.append_column(colName);
		
		//colSize
		colSize = new TreeViewColumn();
		colSize.title = "Size";
		CellRendererText cellSize = new CellRendererText ();
		colSize.pack_start (cellSize, false);
		colSize.set_attributes(cellSize, "text", InputField.FILE_SIZE);
		tvFiles.append_column(colSize);
		
		//colDuration
		colDuration = new TreeViewColumn();
		colDuration.title = "Duration";
		CellRendererText cellDuration = new CellRendererText ();
		colDuration.pack_start (cellDuration, false);
		colDuration.set_attributes(cellDuration, "text", InputField.FILE_DURATION);
		tvFiles.append_column(colDuration);

		//colCrop
		colCrop = new TreeViewColumn();
		colCrop.title = "CropVideo (L:T:R:B)";
		colCrop.fixed_width = 100;
		CellRendererText cellCrop = new CellRendererText ();
		cellCrop.editable = true;
		cellCrop.edited.connect (tvFiles_crop_cell_edited);
		colCrop.pack_start (cellCrop, false);
		colCrop.set_attributes(cellCrop, "text", InputField.FILE_CROPVAL);
		tvFiles.append_column(colCrop);
		
		//colProgress
		colProgress = new TreeViewColumn();
		colProgress.title = "Status";
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

		startupTimer = Timeout.add (100, () => 
		{	
			colProgress.visible = false; 
			Source.remove (startupTimer); 
			return true; 
		});

		Gtk.drag_dest_set (tvFiles,Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);
        tvFiles.drag_data_received.connect(this.on_drag_data_received);
		
		vboxMain.add (vboxMain2);
		
		//hboxScript
		hboxScript = new Box (Orientation.HORIZONTAL, 6);
		hboxScript.homogeneous = false;
        vboxMain2.pack_start (hboxScript, true, true, 6);
        
        //cmbScriptFolder ---------------------

		cmbScriptFolder = new ComboBox();
		cmbScriptFolder.set_size_request(100,-1);
		cmbScriptFolder.set_tooltip_text ("Folder");
		cmbScriptFolder.changed.connect(cmbScriptFolder_changed);
		hboxScript.pack_start (cmbScriptFolder, true, true, 0);

		CellRendererText cellScriptFolder = new CellRendererText();
        cmbScriptFolder.pack_start( cellScriptFolder, false );
        cmbScriptFolder.set_cell_data_func (cellScriptFolder, cellScriptFolder_render);
		
		//cmbScriptFile ----------------------
		
		cmbScriptFile = new ComboBox();
		hboxScript.pack_start (cmbScriptFile, true, true, 0);
		
		CellRendererText cellScriptFile = new CellRendererText();
        cmbScriptFile.pack_start( cellScriptFile, false );
        cmbScriptFile.set_cell_data_func (cellScriptFile, cellScriptFile_render);
        cmbScriptFile.set_tooltip_text ("Encoding Script or Preset File");
        cmbScriptFile.changed.connect(cmbScriptFile_changed);
        
        populate_script_folders();
        
        /*
        //populate
        foreach(ScriptFile sh in App.ScriptFiles){
        	model1.append( out iter );
        	model1.set( iter, 0, sh);
        }
        
        //select default script
        if (App.SelectedScript != null){
			ScriptFile sh = App.find_script(App.SelectedScript.Path);
	        cmbScriptFile.set_active(App.ScriptFiles.index_of(sh));
	    }
	    else{
			cmbScriptFile.set_active(0);
		}
*/

		//btnPresetNew
		btnPresetNew = new Button();
		btnPresetNew.set_image (new Image.from_stock (Stock.ADD, IconSize.MENU));
        btnPresetNew.clicked.connect (btnPresetNew_clicked);
        btnPresetNew.set_tooltip_text ("New Preset");
        hboxScript.add (btnPresetNew);
        
        //btnPresetEdit
		btnPresetEdit = new Button();
		btnPresetEdit.set_image (new Image.from_stock (Stock.EDIT, IconSize.MENU));
        btnPresetEdit.clicked.connect (btnPresetEdit_clicked);
        btnPresetEdit.set_tooltip_text ("Edit Preset");
        hboxScript.add (btnPresetEdit);
        
        //btnOpenScriptFolder
		btnOpenScriptFolder = new Button();
		btnOpenScriptFolder.set_image (new Image.from_stock (Stock.DIRECTORY, IconSize.MENU));
        btnOpenScriptFolder.clicked.connect (btnOpenScriptFolder_clicked);
        btnOpenScriptFolder.set_tooltip_text ("Open script folder");
        hboxScript.add (btnOpenScriptFolder);
        
		// lblStatus
		lblStatus = new Label ("test");
		//lblStatus.margin_bottom = 6;
		//lblStatus.margin_bottom = 6;
		lblStatus.ellipsize = Pango.EllipsizeMode.END;
		vboxMain2.pack_start (lblStatus, false, false, 6);
		
		// hboxProgress
		hboxProgress = new Box (Orientation.HORIZONTAL, 5);
		hboxProgress.visible = false;
		hboxProgress.no_show_all = true;
		hboxProgress.homogeneous = true;
        vboxMain.add (hboxProgress);

		statusbar_default_message ();
		
		// menuFile
		menuFile = new Gtk.Menu();

		// miFileSkip
		miFileSkip = new ImageMenuItem.from_stock (Stock.STOP, null);
		miFileSkip.activate.connect (() => { App.stop_file (); });
		menuFile.append(miFileSkip);
		
		// miFileCropAuto
		miFileCropAuto = new Gtk.MenuItem.with_label ("AutoCrop Video");
		miFileCropAuto.activate.connect(miFileCropAuto_clicked);
		menuFile.append(miFileCropAuto);

		// miFilePreview
		miFilePreview = new Gtk.MenuItem.with_label ("Preview File");
		miFilePreview.activate.connect(miFilePreview_clicked);
		menuFile.append(miFilePreview);		
		
		// miFileRemove
		miFileRemove = new ImageMenuItem.from_stock(Stock.REMOVE, null);
		miFileRemove.activate.connect(miFileRemove_clicked);
		menuFile.append(miFileRemove);	
		
		// miFileSeparator1
		miFileSeparator1 = new Gtk.MenuItem();
		miFileSeparator1.override_color (StateFlags.NORMAL, gray);
		menuFile.append(miFileSeparator1);
		
		// miFileOpenTemp
		miFileOpenTemp = new ImageMenuItem.from_stock(Stock.DIRECTORY, null);
		miFileOpenTemp.label = "Open Temp Folder";
		miFileOpenTemp.activate.connect(miFileOpenTemp_clicked);
		menuFile.append(miFileOpenTemp);
		
		// miFileOpenOutput
		miFileOpenOutput = new ImageMenuItem.from_stock(Stock.DIRECTORY, null);
		miFileOpenOutput.label = "Open Output Folder";
		miFileOpenOutput.activate.connect(miFileOpenOutput_clicked);
		menuFile.append(miFileOpenOutput);
		
		// miFileSeparator2
		miFileSeparator2 = new Gtk.MenuItem();
		miFileSeparator2.override_color (StateFlags.NORMAL, gray);
		menuFile.append(miFileSeparator2);
		
		// miFileInfo
		miFileInfo = new ImageMenuItem.from_stock(Stock.INFO, null);
		miFileInfo.label = "File Info (Source)";
		miFileInfo.activate.connect(miFileInfo_clicked);
		menuFile.append(miFileInfo);
		
		// miFileInfoOutput
		miFileInfoOutput = new ImageMenuItem.from_stock(Stock.INFO, null);
		miFileInfoOutput.label = "File Info (Output)";
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

		select_script(App.SelectedScript.Path);
	}
	
	// script dropdown handlers -----------------------
	
	private void populate_script_folders ()
	{
		TreeStore model = new TreeStore(2, typeof(string), typeof(string));
		cmbScriptFolder.set_model(model);
		TreeIter iter0;

		model.append (out iter0, null);
		model.set (iter0, 0, App.ScriptsFolder_Official, 1, "Official Scripts");
		iter_append_children (model, iter0, App.ScriptsFolder_Official);
		
		model.append (out iter0, null);
		model.set (iter0, 0, App.PresetsFolder_Official,1, "Official Presets");
		iter_append_children (model, iter0, App.PresetsFolder_Official);
		
		model.append (out iter0, null);
		model.set (iter0, 0, App.ScriptsFolder_Custom,1, "Custom Scripts");
		iter_append_children (model, iter0, App.ScriptsFolder_Custom);
		
		model.append (out iter0, null);
		model.set (iter0, 0, App.PresetsFolder_Custom,1, "Custom Presets");
	    iter_append_children (model, iter0, App.PresetsFolder_Custom);
	    
	    model.append (out iter0, null);
		model.set (iter0, 0, App.PresetsFolder_Custom,1, "Other");
	    iter_append_children (model, iter0, App.PresetsFolder_Custom);
	    
	    cmbScriptFolder.set_active(0);
	}
	
	private void iter_append_children (TreeStore model, TreeIter iter0, string path)
	{
		try{
			var dir = File.parse_name (path);
			var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			FileInfo file;
			TreeIter iter1;

			while ((file = enumerator.next_file()) != null) {
				if (file.get_file_type() == FileType.DIRECTORY){
					string dirPath = dir.resolve_relative_path(file.get_name()).get_path();
					string dirName = file.get_name();
					
					model.append(out iter1, iter0);
					model.set(iter1, 0, dirPath, 1, dirName);
					iter_append_children(model, iter1, dir.resolve_relative_path(file.get_name()).get_path());
				}
			} 
		}
        catch(Error e){
	        log_error (e.message);
	    }
		
	}
	
	private void cmbScriptFolder_changed()
	{
		//create empty model
		ListStore model = new ListStore(2, typeof(ScriptFile), typeof(string));
		cmbScriptFile.set_model(model);
		
		if (cmbScriptFolder.active == 4){ return; }

		string path = Utility.Combo_GetSelectedValue(cmbScriptFolder,0,"");
		
		try
		{
			var dir = File.parse_name (path);
	        var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);

	        FileInfo file;
	        while ((file = enumerator.next_file ()) != null) {
		        string filePath = dir.resolve_relative_path(file.get_name()).get_path();
		        string fileName = file.get_name();
		        
		        if (Utility.file_exists(filePath)){
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
        }
        catch(Error e){
	        log_error (e.message);
	    }
	}
	
	private void cmbScriptFile_changed()
	{
		if ((cmbScriptFile == null)||(cmbScriptFile.model == null)||(cmbScriptFile.active < 0)){ return; }
		
		ScriptFile sh;
		TreeIter iter;
		cmbScriptFile.get_active_iter(out iter);
		cmbScriptFile.model.get (iter, 0, out sh, -1);
	}
	
	private bool select_script (string filePath)
	{
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
			//select "Other" folder
			cmbScriptFolder.set_active(4); 
			
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
	
	private bool select_script_recurse_children (string filePath, TreeIter iter0)
	{
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
	
	private void cellScriptFile_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter)
	{
		ScriptFile sh;
		model.get (iter, 0, out sh, -1);
		(cell as Gtk.CellRendererText).text = sh.Title;
	}
	
	private void cellScriptFolder_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter)
	{
		string name;
		model.get (iter, 1, out name, -1);
		(cell as Gtk.CellRendererText).text = name;
	}
	
	private void btnOpenScriptFolder_clicked()
	{
		string path;
		TreeModel model = (TreeModel) cmbScriptFolder.model;
		TreeIter iter;
		cmbScriptFolder.get_active_iter(out iter);
		model.get (iter, 0, out path, -1);
		Utility.exo_open (path); 
	}

	private void btnPresetNew_clicked ()
    {
	    var window = new ConfigWindow();
	    window.Folder = Utility.Combo_GetSelectedValue(cmbScriptFolder,0,"");
	    window.Name = "New Preset";
	    //window.CreateNew = true;
	    window.show_all();
	    window.run();
	    
	    cmbScriptFolder_changed();
	}
	
	private void btnPresetEdit_clicked ()
    {
		if ((cmbScriptFile.model == null)||(cmbScriptFile.active < 0)) { return; }
		
		ScriptFile sh;
		TreeIter iter;
		cmbScriptFile.get_active_iter(out iter);
		cmbScriptFile.model.get (iter, 0, out sh, -1);

	    var window = new ConfigWindow();
	    window.Folder = sh.Folder;
	    window.Name = sh.Title;
	    window.show_all();
	    window.load_script();
	    window.run();
	    
	    cmbScriptFolder_changed();
	}

	// statusbar -------------------
	
    private void statusbar_show_message (string message, bool is_error = false, bool timeout = true)
    {
		Gdk.RGBA red = Gdk.RGBA ();
		Gdk.RGBA white = Gdk.RGBA ();
		red.parse ("rgba(255,0,0,1)");
		white.parse ("rgba(0,0,0,1)");
		
		if (is_error)
			lblStatus.override_color (StateFlags.NORMAL, red);
		else
			lblStatus.override_color (StateFlags.NORMAL, null);
		
		lblStatus.label = message;
		
		if (timeout)
			statusbar_set_timeout ();
	}
	
    private void statusbar_set_timeout ()
    {
		//Source.remove (statusTimer);
		statusTimer = Timeout.add (3000, statusbar_clear);
	}
    
    private bool statusbar_clear ()
    {
		//Source.remove (statusTimer);
		lblStatus.label = "";
		statusbar_default_message ();
		return true;
	}
	
	private void statusbar_default_message ()
	{
		switch (App.Status){
			case AppStatus.NOTSTARTED:
				if (App.InputFiles.size > 0)
					statusbar_show_message("Select a script from the dropdown and click 'Start' to begin", false, false);
				else
					statusbar_show_message("Drag files on this window or click the 'Add' button", false, false);
				break;
				
			case AppStatus.IDLE:
				statusbar_show_message("[Batch completed] Right-click for options or click 'Finish' to continue.", false, false);
				break;
				
			case AppStatus.PAUSED:
				statusbar_show_message("[Paused] Click 'Resume' to continue or 'Stop' to abort.", false, false);
				break;
				
			case AppStatus.RUNNING:
				statusbar_show_message("Converting: '%s'".printf (App.CurrentFile.Path), false, false);
				break;
		}
	}
	
	// file list and context menu -------------------------
	
	private void on_drag_data_received (Gdk.DragContext drag_context, int x, int y, Gtk.SelectionData data, uint info, uint time) 
	{
        foreach(string uri in data.get_uris ()){
			string file = uri.replace("file://","").replace("file:/","");
			file = Uri.unescape_string (file);
			bool valid = App.add_file (file);
			if (!valid){
				statusbar_show_message ("Unknown format: '%s'".printf (file), true, true);
			}
			else {
				statusbar_show_message ("File added: '%s'".printf (file));
			}
		}
        
        refresh_file_list(true);
		
        Gtk.drag_finish (drag_context, true, false, time);
    }

    private bool menuFile_popup (Gtk.Menu popup, Gdk.EventButton? event) 
    {
		TreeSelection selection = tvFiles.get_selection ();
		int index = -1;
		
		if (selection.count_selected_rows () == 1){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			index = int.parse (path.to_string ());
		}
		
		switch(App.Status)
		{
			case AppStatus.NOTSTARTED:
				miFileSkip.visible = false;
				miFileOpenTemp.visible = false;
				miFileOpenOutput.visible = false;
				
				miFileInfo.visible = true;
				miFileInfoOutput.visible = false;
				miFilePreview.visible = true;
				miFileCropAuto.visible = true;
				miFileRemove.visible = true;
				miFileSeparator1.visible = true;
				miFileSeparator2.visible = false;
				
				miFileInfo.sensitive = (selection.count_selected_rows() == 1);
				miFilePreview.sensitive = (selection.count_selected_rows() == 1);
				miFileCropAuto.sensitive = (selection.count_selected_rows() > 0);
				miFileRemove.sensitive = (selection.count_selected_rows() > 0);
				break;
			
			case AppStatus.RUNNING:
				
				miFileSkip.visible = true;
				miFileSeparator1.visible = true;
				miFileSeparator2.visible = false;
				miFileOpenTemp.visible = true;
				miFileOpenOutput.visible = true;
				
				if (selection.count_selected_rows() == 1){
					if (App.InputFiles[index].Status == FileStatus.RUNNING){
						miFileSkip.sensitive = true;
					}
					else{
						miFileSkip.sensitive = false;
					}
					if (Utility.dir_exists(App.InputFiles[index].TempDirectory)){
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
				miFileCropAuto.visible = false;
				miFileRemove.visible = false;
				break;
			
			case AppStatus.IDLE:
			
				miFileOpenTemp.visible = true;
				miFileOpenOutput.visible = true;
				
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
				miFilePreview.visible = false;
				miFileCropAuto.visible = false;
				miFileRemove.visible = false;
				miFileSeparator1.visible = false;
				miFileSeparator2.visible = true;

				string outpath = App.InputFiles[index].OutputFilePath;
				if (outpath != null && outpath.length > 0 && Utility.file_exists(outpath)){
					miFileInfoOutput.sensitive = true;
				}
				else{
					miFileInfoOutput.sensitive = false;
				}
				break;
		}
		
		if (event != null) {
			menuFile.popup (null, null, null, event.button, event.time);
		} else {
			menuFile.popup (null, null, null, 0, Gtk.get_current_event_time ());
		}
		return true;
	}

    private void miFileInfo_clicked () 
    {
		TreeSelection selection = tvFiles.get_selection ();
		
		if (selection.count_selected_rows () > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string ());
			
			var window = new FileInfoWindow(App.InputFiles[index]);
			window.show_all ();
			window.run ();
		}
    }
    
    private void miFileInfoOutput_clicked () 
    {
		TreeSelection selection = tvFiles.get_selection ();
		
		if (selection.count_selected_rows () > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			int index = int.parse (path.to_string ());
			
			MediaFile mf = App.InputFiles[index];

			if (Utility.file_exists(mf.OutputFilePath)){
				MediaFile mfOutput = new MediaFile(mf.OutputFilePath);
				var window = new FileInfoWindow(mfOutput);
				window.show_all ();
				window.run ();
			}
		}	
	}
	
    private void miFileCropAuto_clicked () 
    {
		TreeSelection selection = tvFiles.get_selection ();
		if (selection.count_selected_rows () == 0){ return; }
			
		set_busy (true);
		
		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);
		
		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string ());
			MediaFile file = App.InputFiles[index];
			
			if (file.crop_detect ()){
				((ListStore)tvFiles.model).set (iter, InputField.FILE_CROPVAL, file.crop_values_info ());
			}
			else{
				((ListStore)tvFiles.model).set (iter, InputField.FILE_CROPVAL, "N/A");
			}	
			
			do_events ();
		}

		set_busy (false);
    }
    
    private void miFileRemove_clicked () 
    {
		btnRemoveFiles_clicked ();
    }
    
    private void miFileOpenTemp_clicked () 
    {
		TreeSelection selection = tvFiles.get_selection ();
		if (selection.count_selected_rows () == 0){ return; }
		
		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);
		
		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string ());
			MediaFile mf = App.InputFiles[index];
			Utility.exo_open (mf.TempDirectory);
		}
    }
    
    private void miFileOpenOutput_clicked () 
    {
		TreeSelection selection = tvFiles.get_selection ();
		if (selection.count_selected_rows () == 0){ return; }
		
		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);
		
		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string ());
			MediaFile mf = App.InputFiles[index];
			
			if (App.OutputDirectory.length == 0){
				Utility.exo_open (mf.Location);
			} else{
				Utility.exo_open (App.OutputDirectory);
			}
		}
    }
    
	private void set_busy (bool busy) 
	{
		Gdk.Cursor? cursor = null;

		if (busy){
			cursor = new Gdk.Cursor(Gdk.CursorType.WATCH);
		}
		else{
			cursor = new Gdk.Cursor(Gdk.CursorType.ARROW);
		}

		var window = get_window ();
		if (window != null) {
			window.set_cursor (cursor);
		}
		
		do_events ();
	}
    
    private void do_events ()
    {
		while(Gtk.events_pending ())
			Gtk.main_iteration ();
	}
	
    private void miFilePreview_clicked () 
    {
		TreeSelection selection = tvFiles.get_selection ();
		
		if (selection.count_selected_rows () > 0){
			TreeModel model;
			GLib.List<TreePath> lst = selection.get_selected_rows (out model);
			TreePath path = lst.nth_data (0);
			TreeIter iter;
			model.get_iter (out iter, path);
			int index = int.parse (path.to_string ());
			MediaFile file = App.InputFiles[index];
			
			file.preview_output ();
		}
    }
    
	private void refresh_file_list (bool refresh_model)
	{
		ListStore inputStore = new ListStore (9, typeof(MediaFile), typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (string), typeof (int), typeof (string));
		
		TreeIter iter;
		foreach(MediaFile mFile in App.InputFiles) {
			inputStore.append (out iter);
			inputStore.set (iter, InputField.FILE_REF, mFile);
			inputStore.set (iter, InputField.FILE_PATH, mFile.Path);
	    	inputStore.set (iter, InputField.FILE_NAME, mFile.Name);
	    	inputStore.set (iter, InputField.FILE_SIZE, Utility.format_file_size(mFile.Size));
	    	inputStore.set (iter, InputField.FILE_DURATION, Utility.format_duration(mFile.Duration));
	    	inputStore.set (iter, InputField.FILE_STATUS, Stock.MEDIA_PAUSE);
	    	inputStore.set (iter, InputField.FILE_CROPVAL, mFile.crop_values_info ());
	    	inputStore.set (iter, InputField.FILE_PROGRESS, mFile.ProgressPercent);
	    	inputStore.set (iter, InputField.FILE_PROGRESS_TEXT, mFile.ProgressText);
		}
			
		tvFiles.set_model (inputStore);
		
		tvFiles.columns_autosize ();
	}
	
	public void tvFiles_crop_cell_edited (string path, string new_text) 
	{
		int index = int.parse (path.to_string ());
		MediaFile mf = App.InputFiles[index];
		
		if (new_text == null || new_text.length == 0){
			mf.crop_reset ();
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
		model.set (iter, InputField.FILE_CROPVAL, mf.crop_values_info ());
	}
	
	// toolbar --------------------------------
	
	private void btnAddFiles_clicked ()
	{
		var dlgAddFiles = new Gtk.FileChooserDialog("Add File(s)", this, Gtk.FileChooserAction.OPEN,
							Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
							Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		dlgAddFiles.local_only = true;
 		dlgAddFiles.set_modal (true);
 		dlgAddFiles.set_select_multiple (true);

 		if (dlgAddFiles.run() == Gtk.ResponseType.ACCEPT){
	 		foreach (string file in dlgAddFiles.get_filenames()){
				bool added = App.add_file (file);
				if (added == false){
					statusbar_show_message ("Format not supported: '" + file + "'", true, true);
				}
			}
	 	}
	 	
	 	dlgAddFiles.destroy ();
	 	refresh_file_list(true);
	}
	
	private void btnRemoveFiles_clicked ()
	{
		Gee.ArrayList<MediaFile> list = new Gee.ArrayList<MediaFile>();
		TreeSelection sel = tvFiles.get_selection ();
		
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
	
	private void btnClearFiles_clicked ()
	{
		App.remove_all ();
		refresh_file_list(true);
	}
	
	private void btnAbout_clicked ()
	{
		var dialog = new Gtk.AboutDialog();
		dialog.set_destroy_with_parent (true);
		dialog.set_transient_for (this);
		dialog.set_modal (true);
		
		//dialog.artists = {"", ""};
		dialog.authors = {"Tony George"};
		dialog.documenters = null; 
		dialog.translator_credits = null; 

		dialog.program_name = "Selene Media Encoder";
		dialog.comments = "An audio-video encoder for Linux";
		dialog.copyright = "Copyright © 2013 Tony George (teejee2008@gmail.com)";
		dialog.version = AppVersion;

		dialog.license = 
"""
This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.
""";
		dialog.wrap_license = true;

		dialog.website = "http://teejeetech.blogspot.in";
		dialog.website_label = "TeeJee Tech";

		dialog.response.connect ((response_id) => {
			if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
				dialog.hide_on_delete ();
			}
		});

		dialog.present ();
	}

	private void btnAppSettings_clicked ()
    {
	    var window = new PrefWindow ();
	    window.show_all ();
	    window.run ();
	}
	
	private void btnShutdown_clicked ()
    {
		App.Shutdown = btnShutdown.active;
		
		if (App.Shutdown){
			log_msg ("Shutdown Activated\n");
		}
		else{
			log_msg ("Shutdown Deactivated\n");
		}
	}
	
	private void btnBackground_clicked ()
    {
		App.BackgroundMode = btnBackground.active;
		App.set_priority ();
	}
	
	private void btnPause_clicked ()
    {
		// pause or resume based on value of field 'pause'
	    if (App.Status == AppStatus.RUNNING){
			App.pause (); 
		}
		else if (App.Status == AppStatus.PAUSED){
			App.resume ();   
		}
		
		// set button statepause or resume based on value of field 'pause'
		switch (App.Status){
			case AppStatus.PAUSED:
				btnPause.label = "Resume";
				btnPause.stock_id = "gtk-media-play";
				btnPause.set_tooltip_text ("Resume");
				statusbar_default_message ();
				break; 
			case AppStatus.RUNNING:
				btnPause.label = "Pause";
				btnPause.stock_id = "gtk-media-pause";
				btnPause.set_tooltip_text ("Pause");
				statusbar_default_message ();
				break; 
		}
		
		update_status_all();
	}
	
	private void btnStop_clicked ()
	{
		App.stop_batch();
		update_status_all(); 
	}
	
	// encoding ----------------------------------
	
	public void start ()
	{
		if (App.InputFiles.size == 0){
			string msg = "Input queue is empty!\nPlease add some files.\n";
			Utility.messagebox_show ("Queue is Empty", msg);
			return;
		}	

		convert_prepare ();
		
		ScriptFile sh;
		TreeIter iter;
		cmbScriptFile.get_active_iter(out iter);
		cmbScriptFile.model.get (iter, 0, out sh, -1);
	    App.SelectedScript = sh;
	    
	    App.convert_begin ();
	    
	    timerID = Timeout.add (500, update_status);
	}
	
	public void convert_prepare ()
	{
		hboxScript.visible = false;
		hboxProgress.visible = true;
		btnShutdown.active = App.Shutdown;
		
		btnShutdown.visible = App.AdminMode;
		btnBackground.visible = App.AdminMode;
		btnBackground.visible = App.AdminMode;
        btnBackground.active = App.BackgroundMode;
        
		btnStart.visible = false;
		btnRemoveFiles.visible = false;
		btnClearFiles.visible = false;
		btnAppSettings.visible = false;
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
	} 
	
	public void convert_finish ()
	{
		hboxScript.visible = true;
		hboxProgress.visible = false;

		colCrop.visible = true;
		colProgress.visible = false;
		
		btnStart.visible = true;
		btnRemoveFiles.visible = true;
		btnClearFiles.visible = true;
		btnAppSettings.visible = true;
		btnAbout.visible = true;
		
		btnShutdown.visible = false;
		btnBackground.visible = false;

		btnPause.visible = false;
		btnStop.visible = false;
		btnFinish.visible = false;
		
		App.convert_finish();
		
		statusbar_default_message ();
	} 

	public bool update_status ()
	{
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
					string msg = "System will shutdown in one minute!\n";
					msg += "Press 'Cancel' to abort shutdown";
					var dialog = new Gtk.MessageDialog(null,Gtk.DialogFlags.MODAL,Gtk.MessageType.INFO, Gtk.ButtonsType.CANCEL, msg);
					dialog.set_title("System shutdown");
					
					uint shutdownTimerID = Timeout.add (60000, shutdown);
					App.WaitingForShutdown = true;
					if (dialog.run() == Gtk.ResponseType.CANCEL){
						Source.remove (shutdownTimerID);
						App.WaitingForShutdown = false;
						stdout.printf ("System shutdown was cancelled by user!\n");
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
				btnFinish.visible = true;
				
				// update statusbar message
				statusbar_default_message ();
				
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
				
				if (model.get_iter_from_string (out iter, App.InputFiles.index_of(App.CurrentFile).to_string ())){
					model.set (iter, InputField.FILE_PROGRESS, (int)(App.Progress * 100));
					model.set (iter, InputField.FILE_PROGRESS_TEXT, null);
				}

				lblStatus.label = statusLine;
				break;
		}

		return true;
	}
	
	public void update_status_all ()
	{
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
	
	public bool shutdown ()
	{
		Utility.shutdown ();
		return true;
	}
}

public enum InputField
{
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
