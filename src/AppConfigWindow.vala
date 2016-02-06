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

public class AppConfigWindow : Dialog {

	private Box vboxMain;
	private Label lblView;
	private Label lblOutput;
	private CheckButton chkOutput;
	private FileChooserButton fcbOutput;
	private CheckButton chkBackup;
	private Label lblBackup;
	private FileChooserButton fcbBackup;
	private Button btnSave;
	private Button btnCancel;
	private ComboBox cmbFileView;

	public AppConfigWindow() {
		title = "Settings";
		
        window_position = WindowPosition.CENTER_ON_PARENT;
        destroy_with_parent = true;
        skip_taskbar_hint = true;
		modal = true;
		deletable = false;
		resizable = false;
		icon = get_app_icon(16);

		// get content area
		vboxMain = get_content_area();
		vboxMain.margin = 6;
		vboxMain.set_size_request(350, 400);

		// lblView
		lblView = new Label (_("<b>General</b>"));
		lblView.set_use_markup(true);
		lblView.halign = Align.START;
		lblView.margin_bottom = 12;
		//lblView.margin_top = 12;
		vboxMain.pack_start (lblView, false, true, 0);

		//hboxFileView
		Box hboxFileView = new Box(Orientation.HORIZONTAL,6);
        vboxMain.add(hboxFileView);

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
		model.set (iter, 0, _("Simple"), 1, "list");
		model.append (out iter);
		model.set (iter, 0, _("Tiles"), 1, "tiles");
		cmbFileView.set_model(model);

		if (App.TileView){
			cmbFileView.set_active(1);
		}
		else{
			cmbFileView.set_active(0);
		}

		// lblOutput
		lblOutput = new Label (_("<b>Output Folder</b>"));
		lblOutput.set_use_markup(true);
		lblOutput.halign = Align.START;
		lblOutput.margin_bottom = 12;
		lblOutput.margin_top = 12;
		vboxMain.pack_start (lblOutput, false, true, 0);

		// fcbOutput
		fcbOutput = new FileChooserButton (_("Output Location"), FileChooserAction.SELECT_FOLDER);
		fcbOutput.set_sensitive(App.OutputDirectory.length > 0);
		fcbOutput.margin_left = 6;
		fcbOutput.margin_bottom = 6;
		if ((App.OutputDirectory != null) && dir_exists (App.OutputDirectory)){
			fcbOutput.set_filename (App.OutputDirectory);
		}
		vboxMain.add (fcbOutput);

		// chkOutput
		chkOutput = new CheckButton.with_label (_("Save in input file location"));
		chkOutput.active = (App.OutputDirectory.length == 0);
		chkOutput.margin_left = 6;
		chkOutput.clicked.connect (chkOutput_clicked);
		vboxMain.pack_start (chkOutput, false, true, 0);

		// lblBackup
		lblBackup = new Label (_("<b>Backup Folder</b>"));
		lblBackup.set_use_markup(true);
		lblBackup.halign = Align.START;
		lblBackup.margin_bottom = 12;
		lblBackup.margin_top = 12;
		vboxMain.pack_start (lblBackup, false, true, 0);

		// fcbBackup
		fcbBackup = new FileChooserButton (_("Backup Location"), FileChooserAction.SELECT_FOLDER);
		fcbBackup.set_sensitive(App.BackupDirectory.length > 0);
		fcbBackup.margin_left = 6;
		fcbBackup.margin_bottom = 6;
		if ((App.BackupDirectory.length > 0) && dir_exists (App.BackupDirectory)){
			fcbBackup.set_filename (App.BackupDirectory);
		}
		vboxMain.add (fcbBackup);

		// chkBackup
		chkBackup = new CheckButton.with_label (_("Do not move input files"));
		chkBackup.active = (App.BackupDirectory.length == 0);
		chkBackup.margin_left = 6;
		chkBackup.clicked.connect (chkBackup_clicked);
		vboxMain.pack_start (chkBackup, false, true, 0);

        // btnSave
        btnSave = (Button) add_button ("gtk-save", Gtk.ResponseType.ACCEPT);
        btnSave.clicked.connect (btnSave_clicked);

        // btnCancel
        btnCancel = (Button) add_button ("gtk-cancel", Gtk.ResponseType.CANCEL);
        btnCancel.clicked.connect (btnCancel_clicked);
	}

	private void chkOutput_clicked(){
		fcbOutput.set_sensitive(!chkOutput.active);
	}

	private void chkBackup_clicked(){
		fcbBackup.set_sensitive(!chkBackup.active);
	}

	private void btnSave_clicked(){
		if (chkOutput.active){
			App.OutputDirectory = "";
		}
		else {
			if (dir_exists (fcbOutput.get_filename())){
				App.OutputDirectory = fcbOutput.get_filename();
			}
		}

		if (chkBackup.active){
			App.BackupDirectory = "";
		}
		else {
			if (dir_exists (fcbBackup.get_filename())){
				App.BackupDirectory = fcbBackup.get_filename();
			}
		}

		App.TileView = (cmbFileView.active == 1);

		// Save settings
		App.save_config();

		destroy();
	}

	private void btnCancel_clicked(){
		destroy();
	}
}
