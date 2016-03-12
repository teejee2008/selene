/*
 * PrefWindow.vala
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

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class AppConfigWindow : Gtk.Dialog {
	private Box vboxMain;
	private Gtk.Notebook notebook;
	private Label lblView;
	private Label lblOutput;
	private CheckButton chkOutput;
	private Entry txtBackup;
	private CheckButton chkBackup;
	private Label lblBackup;
	private Entry txtOutput;
	private Button btnSave;
	private Button btnCancel;
	private ComboBox cmbFileView;
	private ComboBox cmbSelectEncoder;
	private ComboBox cmbSelectPlayer;
	private ComboBox cmbDefaultLanguage;
	
	public AppConfigWindow(Gtk.Window parent) {
		title = "Settings";

		set_transient_for(parent);
		set_modal(true);
		
        window_position = WindowPosition.CENTER_ON_PARENT;
        destroy_with_parent = true;
        skip_taskbar_hint = true;
		modal = true;
		deletable = true;
		resizable = false;
		icon = get_app_icon(16);

		// get content area
		vboxMain = get_content_area();
		vboxMain.set_size_request(400,500);

		//notebook
		notebook = new Notebook();
		notebook.tab_pos = PositionType.TOP;
		notebook.show_border = true;
		notebook.scrollable = true;
		notebook.margin = 6;
		vboxMain.pack_start (notebook, true, true, 0);
		
		init_ui_tab_general();

		init_ui_tab_tools();
		
        // btnSave
        btnSave = (Button) add_button ("gtk-save", Gtk.ResponseType.ACCEPT);
        btnSave.clicked.connect (btnSave_clicked);

        // btnCancel
        btnCancel = (Button) add_button ("gtk-cancel", Gtk.ResponseType.CANCEL);
        btnCancel.clicked.connect (btnCancel_clicked);

        chkOutput_clicked();
        chkBackup_clicked();

        show_all();
	}

	private void init_ui_tab_general(){
		//lblTabGeneral
		var lblTabGeneral = new Label (_("General"));

        //vboxTabGeneral
        var vboxTabGeneral = new Box(Orientation.VERTICAL,6);
        vboxTabGeneral.margin = 12;
        notebook.append_page (vboxTabGeneral, lblTabGeneral);

		// lblOutput
		lblOutput = new Label (_("<b>Output Directory</b>"));
		lblOutput.set_use_markup(true);
		lblOutput.halign = Align.START;
		vboxTabGeneral.pack_start (lblOutput, false, true, 0);

		// chkOutput
		chkOutput = new CheckButton.with_label (_("Save files in following location"));
		chkOutput.active = (App.OutputDirectory.length > 0);
		chkOutput.clicked.connect (chkOutput_clicked);
		vboxTabGeneral.pack_start (chkOutput, false, true, 0);
		
		// txtOutput
		txtOutput = new Gtk.Entry();
		txtOutput.hexpand = true;
		txtOutput.secondary_icon_stock = "gtk-open";
		txtOutput.placeholder_text = _("Enter path or browse for directory");
		vboxTabGeneral.add (txtOutput);

		if ((App.OutputDirectory != null) && dir_exists (App.OutputDirectory)){
			txtOutput.text = App.OutputDirectory;
		}

		txtOutput.icon_release.connect((p0, p1) => {
			//chooser
			var chooser = new Gtk.FileChooserDialog(
			    _("Select Path"),
			    this,
			    FileChooserAction.SELECT_FOLDER,
			    "_Cancel",
			    Gtk.ResponseType.CANCEL,
			    "_Open",
			    Gtk.ResponseType.ACCEPT
			);

			chooser.select_multiple = false;
			chooser.set_filename(App.OutputDirectory);

			if (chooser.run() == Gtk.ResponseType.ACCEPT) {
				txtOutput.text = chooser.get_filename();
			}

			chooser.destroy();
		});

		// lblBackup
		lblBackup = new Label (_("<b>Backup Directory</b>"));
		lblBackup.set_use_markup(true);
		lblBackup.halign = Align.START;
		lblBackup.margin_top = 12;
		vboxTabGeneral.pack_start (lblBackup, false, true, 0);

		// chkBackup
		chkBackup = new CheckButton.with_label (_("Move source files after encoding is complete"));
		chkBackup.active = (App.BackupDirectory.length > 0);
		chkBackup.clicked.connect (chkBackup_clicked);
		vboxTabGeneral.pack_start (chkBackup, false, true, 0);
		
		// txtBackup
		txtBackup = new Gtk.Entry();
		txtBackup.hexpand = true;
		txtBackup.secondary_icon_stock = "gtk-open";
		txtBackup.placeholder_text = _("Enter path or browse for directory");
		vboxTabGeneral.add (txtBackup);

		if ((App.BackupDirectory != null) && dir_exists (App.BackupDirectory)){
			txtBackup.text = App.BackupDirectory;
		}

		txtBackup.icon_release.connect((p0, p1) => {
			//chooser
			var chooser = new Gtk.FileChooserDialog(
			    _("Select Path"),
			    this,
			    FileChooserAction.SELECT_FOLDER,
			    "_Cancel",
			    Gtk.ResponseType.CANCEL,
			    "_Open",
			    Gtk.ResponseType.ACCEPT
			);

			chooser.select_multiple = false;
			chooser.set_filename(App.BackupDirectory);

			if (chooser.run() == Gtk.ResponseType.ACCEPT) {
				txtBackup.text = chooser.get_filename();
			}

			chooser.destroy();
		});

		// lblView
		lblView = new Label (_("<b>Main Window</b>"));
		lblView.set_use_markup(true);
		lblView.halign = Align.START;
		//lblView.margin_bottom = 12;
		lblView.margin_top = 12;
		vboxTabGeneral.pack_start (lblView, false, true, 0);
		
		//hboxFileView
		Box hboxFileView = new Box(Orientation.HORIZONTAL,6);
        vboxTabGeneral.add(hboxFileView);

		Label lblFileView = new Gtk.Label(_("File View"));
		lblFileView.xalign = (float) 0.0;
		hboxFileView.pack_start(lblFileView,false,false,0);

		cmbFileView = new ComboBox();
		var textCell = new CellRendererText();
        cmbFileView.pack_start(textCell, false);
        cmbFileView.set_attributes(textCell, "text", 0);
		hboxFileView.pack_start(cmbFileView,false,false,0);

		Gtk.TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("List"), 1, "list");
		model.append (out iter);
		model.set (iter, 0, _("Tiles"), 1, "tiles");
		cmbFileView.set_model(model);

		if (App.TileView){
			cmbFileView.set_active(1);
		}
		else{
			cmbFileView.set_active(0);
		}

	}

	private void init_ui_tab_tools(){
		//lblTabTools
		var lblTabTools = new Label (_("Tools"));

        //vboxTabTools
        var vboxTabTools = new Box(Orientation.VERTICAL,6);
        vboxTabTools.margin = 12;
        notebook.append_page (vboxTabTools, lblTabTools);
		
		Gtk.SizeGroup sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
		
		//hboxEncoder -----------------------------------------------
		
		var hboxEncoder = new Gtk.Box(Orientation.HORIZONTAL,6);
		vboxTabTools.pack_start (hboxEncoder, false, true, 0);

		//lblSelectEncoder
		var lblSelectEncoder = new Label ("Use FFmpeg or Libav encoder");
		lblSelectEncoder.set_use_markup(true);
		lblSelectEncoder.halign = Align.START;
		lblSelectEncoder.hexpand = true;
		hboxEncoder.add(lblSelectEncoder);
		
		//cmbSelectEncoder
		TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("ffmpeg"), 1, "ffmpeg");
		model.append (out iter);
		model.set (iter, 0, _("avconv / Libav"), 1, "avconv");

		cmbSelectEncoder = new ComboBox.with_model(model);
		hboxEncoder.add(cmbSelectEncoder);
		sizegroup.add_widget(cmbSelectEncoder);
		
		var textCell = new CellRendererText();
        cmbSelectEncoder.pack_start( textCell, false );
        cmbSelectEncoder.set_attributes( textCell, "text", 0 );
			
        string tt = _("<b>avconv</b>\nUse the 'avconv' encoding tool from the Libav project\n\n");
        tt += _("<b>Encoder</b>\nUse the 'ffmpeg' encoding tool from the FFmpeg project (Recommended)\n\n");
        cmbSelectEncoder.set_tooltip_markup(tt);
		lblSelectEncoder.set_tooltip_markup(tt);
		
		switch(App.PrimaryEncoder){
		case "ffmpeg":
			cmbSelectEncoder.active = 0;
			break;
		case "avconv":
			cmbSelectEncoder.active = 1;
			break;
		default:
			cmbSelectEncoder.active = 0;
			break;
		}

		//hboxPlayer -----------------------------------------------
		
		var hboxPlayer = new Gtk.Box(Orientation.HORIZONTAL,6);
		vboxTabTools.pack_start (hboxPlayer, false, true, 0);

		//lblSelectPlayer
		var lblSelectPlayer = new Label ("Use Mpv or MPlayer");
		lblSelectPlayer.set_use_markup(true);
		lblSelectPlayer.halign = Align.START;
		lblSelectPlayer.hexpand = true;
		hboxPlayer.add(lblSelectPlayer);
		
		//cmbSelectPlayer
		//TreeIter iter;
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("mpv"), 1, "mpv");
		model.append (out iter);
		model.set (iter, 0, _("mplayer"), 1, "mplayer");

		cmbSelectPlayer = new ComboBox.with_model(model);
		hboxPlayer.add(cmbSelectPlayer);
		sizegroup.add_widget(cmbSelectPlayer);
		
		textCell = new CellRendererText();
        cmbSelectPlayer.pack_start( textCell, false );
        cmbSelectPlayer.set_attributes( textCell, "text", 0 );
			
        //string tt = _("<b>avconv</b>\nUse the 'avconv' encoding tool from the Libav project\n\n");
        //tt += _("<b>Player</b>\nUse the 'ffmpeg' encoding tool from the FFmpeg project (Recommended)\n\n");
        //cmbSelectPlayer.set_tooltip_markup(tt);
		//lblSelectPlayer.set_tooltip_markup(tt);
		
		switch(App.PrimaryPlayer){
		case "mpv":
			cmbSelectPlayer.active = 0;
			break;
		case "mplayer":
			cmbSelectPlayer.active = 1;
			break;
		default:
			cmbSelectPlayer.active = 0;
			break;
		}

		//cmbDefaultLanguage

		var hbox = new Gtk.Box(Orientation.HORIZONTAL,6);
		vboxTabTools.pack_start (hbox, false, true, 0);

		//Default Language ---------------------------------------------

		//lbl ------------
		
		var lbl = new Label ("Default Language");
		lbl.set_use_markup(true);
		lbl.halign = Align.START;
		lbl.hexpand = true;
		tt = "Will be used for setting the default track when encoding files with multiple audio and subtitle tracks";
		lbl.set_tooltip_text(tt);
		hbox.add(lbl);

		//combo -------------
		
		int index = -1;
		int selectedIndex = 0;
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		foreach(var lang in LanguageCodes.lang_list){
			model.append (out iter);
			model.set (iter, 0, lang.Name, 1, lang.Code2);
			index++;

			if (lang.Code2 == App.DefaultLanguage){
				selectedIndex = index;
			}
		}
	
		cmbDefaultLanguage = new ComboBox.with_model(model);
		cmbDefaultLanguage.active = selectedIndex;
		cmbDefaultLanguage.set_tooltip_text(tt);
		hbox.add(cmbDefaultLanguage);
		//sizegroup.add_widget(cmbDefaultLanguage);
		
		textCell = new CellRendererText();
		textCell.ellipsize = Pango.EllipsizeMode.END;
		textCell.max_width_chars = 20;
        cmbDefaultLanguage.pack_start( textCell, false );
        cmbDefaultLanguage.set_attributes( textCell, "text", 0 );
	}
	
	private void chkOutput_clicked(){
		txtOutput.set_sensitive(chkOutput.active);
	}

	private void chkBackup_clicked(){
		txtBackup.set_sensitive(chkBackup.active);
	}

	private void btnSave_clicked(){
		if (chkOutput.active){
			if (dir_exists(txtOutput.text)){
				App.OutputDirectory = txtOutput.text;
			}
			else{
				App.OutputDirectory = "";
			}
		}
		else {
			App.OutputDirectory = "";
		}

		if (chkBackup.active){
			if (dir_exists(txtBackup.text)){
				App.BackupDirectory = txtBackup.text;
			}
			else{
				App.BackupDirectory = "";
			}
		}
		else {
			App.BackupDirectory = "";
		}

		App.TileView = (cmbFileView.active == 1);

		App.PrimaryEncoder = gtk_combobox_get_value(cmbSelectEncoder,1,"ffmpeg");
		App.PrimaryPlayer = gtk_combobox_get_value(cmbSelectPlayer,1,"mpv");
		App.DefaultLanguage = gtk_combobox_get_value(cmbDefaultLanguage,1,"en");
		
		// Save settings
		App.save_config();

		destroy();
	}

	private void btnCancel_clicked(){
		destroy();
	}
}
