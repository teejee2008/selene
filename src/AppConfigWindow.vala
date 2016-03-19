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
	private Box vbox_main;
	private Gtk.Notebook notebook;
	private CheckButton chk_output_dir;
	private Entry txt_backup_dir;
	private CheckButton chk_backup_dir;
	private Entry txt_output_dir;
	private Button btn_save;
	private Button btn_cancel;
	private ComboBox cmb_file_view;
	private ComboBox cmb_select_encoder;
	private ComboBox cmb_select_player;
	private ComboBox cmb_def_lang;
	private CheckButton chk_delete_temp;
	
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
		vbox_main = get_content_area();
		vbox_main.set_size_request(400,500);

		//notebook
		notebook = new Notebook();
		notebook.tab_pos = PositionType.TOP;
		notebook.show_border = true;
		notebook.scrollable = true;
		notebook.margin = 6;
		vbox_main.pack_start (notebook, true, true, 0);
		
		init_ui_tab_general();

		init_ui_tab_tools();
		
        // btn_save
        btn_save = (Button) add_button ("gtk-save", Gtk.ResponseType.ACCEPT);
        btn_save.clicked.connect (btn_save_clicked);

        // btn_cancel
        btn_cancel = (Button) add_button ("gtk-cancel", Gtk.ResponseType.CANCEL);
        btn_cancel.clicked.connect (btn_cancel_clicked);

        chk_output_dir_clicked();
        chk_backup_dir_clicked();

        show_all();
	}

	private void init_ui_tab_general(){
		
		// add tab ------------------------------
		
		var label = new Label (_("General"));

        var vbox = new Box(Orientation.VERTICAL,6);
        vbox.margin = 12;
        notebook.append_page (vbox, label);

		// output dir --------------------------------------------
		
		label = new Label (_("<b>Output Directory</b>"));
		label.set_use_markup(true);
		label.halign = Align.START;
		//label.margin_top = 12;
		label.margin_bottom = 6;
		vbox.pack_start (label, false, true, 0);

		// chk_output_dir
		var chk = new CheckButton.with_label (_("Save files in following location"));
		chk.margin_left = 6;
		chk.active = (App.OutputDirectory.length > 0);
		chk.clicked.connect (chk_output_dir_clicked);
		vbox.pack_start (chk, false, true, 0);
		chk_output_dir = chk;
		
		// txt_output_dir
		var txt = new Gtk.Entry();
		txt.hexpand = true;
		txt.margin_left = 6;
		txt.secondary_icon_stock = "gtk-open";
		txt.placeholder_text = _("Enter path or browse for directory");
		vbox.add (txt);
		txt_output_dir = txt;
		
		if ((App.OutputDirectory != null) && dir_exists (App.OutputDirectory)){
			txt_output_dir.text = App.OutputDirectory;
		}

		txt_output_dir.icon_release.connect((p0, p1) => {
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
				txt_output_dir.text = chooser.get_filename();
			}

			chooser.destroy();
		});

		// backup dir -----------------------------------------------
		
		label = new Label (_("<b>Backup Directory</b>"));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		label.margin_bottom = 6;
		vbox.pack_start (label, false, true, 0);

		// chk_backup_dir
		chk = new CheckButton.with_label (_("Move source files after encoding is complete"));
		chk.margin_left = 6;
		chk.active = (App.BackupDirectory.length > 0);
		chk.clicked.connect (chk_backup_dir_clicked);
		vbox.pack_start (chk, false, true, 0);
		chk_backup_dir = chk;
		
		// txt_backup_dir
		txt = new Gtk.Entry();
		txt.hexpand = true;
		txt.margin_left = 6;
		txt.secondary_icon_stock = "gtk-open";
		txt.placeholder_text = _("Enter path or browse for directory");
		vbox.add (txt);
		txt_backup_dir = txt;
		
		if ((App.BackupDirectory != null) && dir_exists (App.BackupDirectory)){
			txt.text = App.BackupDirectory;
		}

		txt.icon_release.connect((p0, p1) => {
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
				txt_backup_dir.text = chooser.get_filename();
			}

			chooser.destroy();
		});

		// header ---------------------------------------------
		
		label = new Label (_("<b>Main Window</b>"));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		label.margin_bottom = 6;
		vbox.pack_start (label, false, true, 0);

		// file view -------------------------------------
		
		var hbox = new Box(Orientation.HORIZONTAL,12);
        vbox.add(hbox);

		label = new Gtk.Label(_("File View"));
		label.xalign = (float) 0.0;
		label.margin_left = 6;
		hbox.pack_start(label,false,false,0);

		// cmb_file_view
		var combo = new ComboBox();
		var textCell = new CellRendererText();
        combo.pack_start(textCell, false);
        combo.set_attributes(textCell, "text", 0);
		hbox.pack_start(combo,false,false,0);
		cmb_file_view = combo;
		
		Gtk.TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("List"), 1, "list");
		model.append (out iter);
		model.set (iter, 0, _("Tiles"), 1, "tiles");
		combo.set_model(model);

		if (App.TileView){
			combo.set_active(1);
		}
		else{
			combo.set_active(0);
		}
	}

	private void init_ui_tab_tools(){
		
		// add tab ---------------------------------------
		
		var label = new Label (_("Tools"));

        var vbox = new Box(Orientation.VERTICAL,6);
        vbox.margin = 12;
        notebook.append_page (vbox, label);
		
		var sizegroup_lbl = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
		var sizegroup_cmb = new Gtk.SizeGroup (Gtk.SizeGroupMode.BOTH);
		
		// header
		label = new Label (_("<b>Preferred Tools</b>"));
		label.set_use_markup(true);
		label.halign = Align.START;
		//label.margin_top = 6;
		label.margin_bottom = 6;
		vbox.pack_start (label, false, true, 0);
		
		// select encoder -----------------------------------------------
		
		var hbox = new Gtk.Box(Orientation.HORIZONTAL,12);
		vbox.pack_start (hbox, false, true, 0);

		string tt = _("<b>avconv</b>\nUse the 'avconv' encoding tool from the Libav project\n\n");
        tt += _("<b>Encoder</b>\nUse the 'ffmpeg' encoding tool from the FFmpeg project (Recommended)\n\n");
        
		label = new Label (_("Encoder"));
		label.xalign = (float) 1.0;
		label.set_use_markup(true);
		label.set_tooltip_markup(tt);
		label.halign = Align.START;
		label.margin_left = 6;
		hbox.add(label);

		sizegroup_lbl.add_widget(label);
		
		//cmb_select_encoder
		TreeIter iter;
		var model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("ffmpeg"), 1, "ffmpeg");
		model.append (out iter);
		model.set (iter, 0, _("avconv / Libav"), 1, "avconv");

		var combo = new ComboBox.with_model(model);
		combo.set_tooltip_markup(tt);
		hbox.add(combo);
		cmb_select_encoder = combo;
		
		sizegroup_cmb.add_widget(combo);
		
		var textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );

		switch(App.PrimaryEncoder){
		case "ffmpeg":
			combo.active = 0;
			break;
		case "avconv":
			combo.active = 1;
			break;
		default:
			combo.active = 0;
			break;
		}

		// selected player ------------------------------------
		
		hbox = new Gtk.Box(Orientation.HORIZONTAL,12);
		vbox.pack_start (hbox, false, true, 0);

		label = new Label(_("Player"));
		label.xalign = (float) 1.0;
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_left = 6;
		hbox.add(label);

		sizegroup_lbl.add_widget(label);
		
		//cmb_select_player
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter, 0, _("mpv"), 1, "mpv");
		model.append (out iter);
		model.set (iter, 0, _("mplayer"), 1, "mplayer");

		combo = new ComboBox.with_model(model);
		hbox.add(combo);
		cmb_select_player = combo;
		
		sizegroup_cmb.add_widget(combo);
		
		textCell = new CellRendererText();
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );
			
		switch(App.PrimaryPlayer){
		case "mpv":
			combo.active = 0;
			break;
		case "mplayer":
			combo.active = 1;
			break;
		default:
			combo.active = 0;
			break;
		}

		// header ---------------
		
		label = new Label (_("<b>Default Language</b>"));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		label.margin_bottom = 6;
		vbox.pack_start (label, false, true, 0);

		// default language --------------------------------------

		hbox = new Gtk.Box(Orientation.HORIZONTAL,12);
		vbox.pack_start (hbox, false, true, 0);

		tt = _("Selected language will be used for setting the default flag on the audio/subtitle track");
		
		label = new Label (_("Language"));
		label.xalign = (float) 1.0;
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_left = 6;
		label.set_tooltip_text(tt);
		hbox.add(label);

		sizegroup_lbl.add_widget(label);
		
		// cmb_def_lang
		int index = -1;
		int selectedIndex = 0;
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		foreach(var lang in LanguageCodes.lang_list){
			model.append (out iter);
			model.set (iter, 0, "%s (%s)".printf(lang.Name, (lang.Code2 == "") ? lang.Code3 : lang.Code2), 1, lang.Code2);
			index++;

			if (lang.Code2 == App.DefaultLanguage){
				selectedIndex = index;
			}
		}
	
		combo = new ComboBox.with_model(model);
		combo.active = selectedIndex;
		combo.set_tooltip_text(tt);
		hbox.add(combo);
		cmb_def_lang = combo;

		//sizegroup_cmb.add_widget(combo);
		
		textCell = new CellRendererText();
		textCell.ellipsize = Pango.EllipsizeMode.END;
		textCell.max_width_chars = 20;
        combo.pack_start( textCell, false );
        combo.set_attributes( textCell, "text", 0 );

		// header ------------------------------------------
		
		label = new Label (_("<b>File Handling</b>"));
		label.set_use_markup(true);
		label.halign = Align.START;
		label.margin_top = 12;
		label.margin_bottom = 6;
		vbox.pack_start (label, false, true, 0);

		tt = _("The temporary folder contains files which may be useful for advanced users. Keep this un-checked if you want to keep the temp files till the next reboot.");
		
        //chk_delete_temp
		var chk = new CheckButton.with_label(_("Delete temporary files after successful encode"));
		chk.active = App.DeleteTempFiles;
		chk.set_tooltip_text(tt);
		chk.margin_left = 6;
		vbox.pack_start (chk, false, true, 0);
		chk_delete_temp = chk;
	}
	
	private void chk_output_dir_clicked(){
		txt_output_dir.set_sensitive(chk_output_dir.active);
	}

	private void chk_backup_dir_clicked(){
		txt_backup_dir.set_sensitive(chk_backup_dir.active);
	}

	private void btn_save_clicked(){
		if (chk_output_dir.active){
			if (dir_exists(txt_output_dir.text)){
				App.OutputDirectory = txt_output_dir.text;
			}
			else{
				App.OutputDirectory = "";
			}
		}
		else {
			App.OutputDirectory = "";
		}

		if (chk_backup_dir.active){
			if (dir_exists(txt_backup_dir.text)){
				App.BackupDirectory = txt_backup_dir.text;
			}
			else{
				App.BackupDirectory = "";
			}
		}
		else {
			App.BackupDirectory = "";
		}

		App.TileView = (cmb_file_view.active == 1);

		App.DeleteTempFiles = chk_delete_temp.active;
		
		App.PrimaryEncoder = gtk_combobox_get_value(cmb_select_encoder,1,"ffmpeg");
		App.PrimaryPlayer = gtk_combobox_get_value(cmb_select_player,1,"mpv");
		App.DefaultLanguage = gtk_combobox_get_value(cmb_def_lang,1,"en");
		
		// Save settings
		App.save_config();

		destroy();
	}

	private void btn_cancel_clicked(){
		destroy();
	}
}
